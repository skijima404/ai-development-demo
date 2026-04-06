#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const cwd = process.cwd();
const rawArgs = process.argv.slice(2);
const args = new Set(rawArgs);
const failOnBlocking = args.has("--fail-on-blocking");
const requestText = readOptionValue(rawArgs, "--request");

const FINDING_ORDER = { blocking: 0, warning: 1, advisory: 2 };
const AMBIGUOUS_WORDS = ["適切", "必要に応じて", "十分", "適宜", "可能なら", "望ましい"];
const TOP_LEVEL_CHANGE_KEYWORDS = [
  "vision",
  "ビジョン",
  "ゴール",
  "目標",
  "mvp",
  "対象外",
  "成功指標",
  "adr",
  "方針",
  "方向転換",
  "プロダクトゴール",
  "product vision",
];
const IMPLEMENTATION_INTENT_KEYWORDS = ["作って", "実装", "追加", "対応", "開発", "作る"];

const DOC_RULES = {
  "docs/traceability/intents/": {
    label: "intent",
    requiredFields: ["intent_id", "title", "owner", "status", "created_at", "updated_at"],
    requiredSections: ["## 望む変化", "## 問題", "## 境界", "## 成功シグナル", "## 下流成果物", "## 参考"],
    boundaryMarkers: ["対象外"],
  },
  "docs/traceability/enabler-proposals/": {
    label: "enabler proposal",
    requiredFields: ["intent_id", "title", "owner", "status", "created_at", "updated_at"],
    requiredSections: ["## 目的", "## 問題", "## 資産定義", "## 成功基準", "## スコープ", "## 運用上の使い方", "## 変更契約", "## 未解決事項", "## 参考"],
    boundaryMarkers: ["対象外"],
  },
  "docs/traceability/feature-proposals/": {
    label: "feature proposal",
    requiredFields: ["intent_id", "title", "owner", "status", "created_at", "updated_at"],
    requiredSections: ["## 意図", "## 問題", "## 成功基準", "## スコープ", "## 制約", "## 変更契約", "## 参考"],
    recommendedSections: ["## 未解決事項"],
    boundaryMarkers: ["対象外"],
  },
  "docs/traceability/implementation-specs/": {
    label: "implementation spec",
    requiredFields: ["intent_id", "title", "owner", "status", "created_at", "updated_at"],
    requiredSections: ["## 基盤との整合", "## 目標", "## スコープ", "## 実行メモ", "## 実装の流れ", "## 検証"],
    recommendedSections: ["## 変更契約"],
    boundaryMarkers: ["対象外"],
  },
  "docs/traceability/value-streams/": {
    label: "value stream",
    requiredFields: ["intent_id", "title", "owner", "status", "created_at", "updated_at"],
    requiredSections: ["## 目的", "## 開始条件", "## 価値の流れ", "## 段階ごとの価値", "## 重要なプロダクト仮説", "## この価値の流れの失敗モード", "## 必須の支援資産"],
    boundaryMarkers: ["対象外", "運用境界"],
  },
  "docs/traceability/ui-specs/": {
    label: "ui spec",
    requiredFields: ["intent_id", "title", "owner", "status", "created_at", "updated_at"],
    requiredSections: ["## UX 意図", "## 利用フロー", "## 画面 / コンポーネント範囲", "## 操作ルール", "## 文言メモ", "## アクセシビリティと品質メモ", "## 受け入れ確認"],
  },
};

function readFile(filePath) {
  return fs.readFileSync(path.join(cwd, filePath), "utf8");
}

function readOptionValue(argv, optionName) {
  const optionIndex = argv.indexOf(optionName);
  if (optionIndex === -1) {
    return "";
  }
  return argv[optionIndex + 1] ?? "";
}

function exists(filePath) {
  return fs.existsSync(path.join(cwd, filePath));
}

function referenceExists(filePath) {
  if (!filePath.includes("*")) {
    return exists(filePath);
  }

  const prefix = filePath.split("*")[0].replace(/\/+$/, "");
  if (!prefix) {
    return true;
  }
  return exists(prefix);
}

function collectFiles(baseDir) {
  const result = [];
  const absBaseDir = path.join(cwd, baseDir);

  function walk(currentDir) {
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });
    for (const entry of entries) {
      const absPath = path.join(currentDir, entry.name);
      const relPath = path.relative(cwd, absPath).replaceAll(path.sep, "/");
      if (entry.isDirectory()) {
        walk(absPath);
      } else if (entry.isFile()) {
        result.push(relPath);
      }
    }
  }

  walk(absBaseDir);
  return result.sort();
}

function addFinding(findings, severity, file, message) {
  findings.push({ severity, file, message });
}

function classifyRequestMode(text) {
  if (!text.trim()) {
    return { mode: "docs_review", reasons: [] };
  }

  const lower = text.toLowerCase();
  const topLevelMatches = TOP_LEVEL_CHANGE_KEYWORDS.filter((keyword) => lower.includes(keyword));
  const implementationMatches = IMPLEMENTATION_INTENT_KEYWORDS.filter((keyword) => text.includes(keyword));

  if (topLevelMatches.length > 0) {
    return {
      mode: "top_level_source_change",
      reasons: topLevelMatches,
      implementationIntentDetected: implementationMatches.length > 0,
    };
  }

  return {
    mode: "standard_requirement",
    reasons: implementationMatches,
    implementationIntentDetected: implementationMatches.length > 0,
  };
}

function findRule(filePath) {
  return Object.entries(DOC_RULES).find(([prefix]) => filePath.startsWith(prefix))?.[1] ?? null;
}

function parseBulletMetadata(content) {
  const lines = content.split("\n");
  const metadata = new Map();
  for (const line of lines) {
    const match = line.match(/^- ([a-z_]+):\s*(.+)?$/);
    if (!match) {
      continue;
    }
    metadata.set(match[1], (match[2] ?? "").trim());
  }
  return metadata;
}

function extractCodePaths(content) {
  const paths = new Set();
  const regex = /`((?:docs|deploy|scripts|src)\/[^`]+)`/g;
  let match;
  while ((match = regex.exec(content)) !== null) {
    paths.add(match[1]);
  }
  return [...paths];
}

function parseRegistry(content) {
  const lines = content.split("\n");
  const rows = [];
  for (const line of lines) {
    if (!line.startsWith("| intent-")) {
      continue;
    }
    const cells = line.split("|").slice(1, -1).map((value) => value.trim());
    rows.push({
      intent_id: cells[0],
      proposal_type: cells[1],
      title: cells[2],
      stage: cells[3],
      enabler_proposal: cells[4],
      feature_proposal: cells[5],
      related_enablers: cells[6],
      ui_spec: cells[7],
      implementation_spec: cells[8],
      status: cells[9],
      updated_at: cells[10],
    });
  }
  return rows;
}

function intentFilesById() {
  const map = new Map();
  for (const filePath of collectFiles("docs/traceability/intents")) {
    const content = readFile(filePath);
    const metadata = parseBulletMetadata(content);
    if (metadata.has("intent_id")) {
      map.set(metadata.get("intent_id"), filePath);
    }
  }
  return map;
}

function checkRegistry(findings, registryPath, intentMap) {
  const content = readFile(registryPath);
  const rows = parseRegistry(content);

  for (const row of rows) {
    if (!intentMap.has(row.intent_id)) {
      addFinding(findings, "blocking", registryPath, `${row.intent_id} に対応する intent 文書が見つかりません。`);
    }

    for (const field of ["enabler_proposal", "feature_proposal", "ui_spec", "implementation_spec"]) {
      const value = row[field];
      if (!value) {
        continue;
      }
      if (!exists(value)) {
        addFinding(findings, "blocking", registryPath, `${row.intent_id} の ${field} が存在しません: ${value}`);
      }
    }

    const rowDate = row.updated_at;
    const intentPath = intentMap.get(row.intent_id);
    if (intentPath && rowDate) {
      const intentDate = parseBulletMetadata(readFile(intentPath)).get("updated_at");
      if (intentDate && intentDate !== rowDate) {
        addFinding(findings, "warning", registryPath, `${row.intent_id} の updated_at が registry (${rowDate}) と intent (${intentDate}) で一致していません。`);
      }
    }
  }
}

function checkDocFile(findings, filePath) {
  const content = readFile(filePath);
  const metadata = parseBulletMetadata(content);
  const rule = findRule(filePath);

  if (rule) {
    for (const field of rule.requiredFields) {
      if (!metadata.get(field)) {
        addFinding(findings, "blocking", filePath, `${rule.label} に必須メタデータ ${field} がありません。`);
      }
    }

    for (const section of rule.requiredSections) {
      if (!content.includes(section)) {
        addFinding(findings, "blocking", filePath, `${rule.label} に必須節 ${section} がありません。`);
      }
    }

    for (const section of rule.recommendedSections ?? []) {
      if (!content.includes(section)) {
        addFinding(findings, "warning", filePath, `${rule.label} に推奨節 ${section} がありません。`);
      }
    }
  }

  for (const referencedPath of extractCodePaths(content)) {
    if (!referenceExists(referencedPath)) {
      addFinding(findings, "blocking", filePath, `参照先が存在しません: ${referencedPath}`);
    }
  }

  if (!content.match(/^# /m)) {
    addFinding(findings, "blocking", filePath, "文書タイトルの H1 がありません。");
  }

  if (rule?.boundaryMarkers && !rule.boundaryMarkers.some((marker) => content.includes(marker))) {
    addFinding(findings, "warning", filePath, "対象外の記述が見当たらず、境界が曖昧です。");
  }

  const ambiguousHits = AMBIGUOUS_WORDS.filter((word) => content.includes(word));
  if (ambiguousHits.length >= 3) {
    addFinding(findings, "advisory", filePath, `曖昧語が多めです: ${ambiguousHits.join(", ")}`);
  }

  const longLines = content.split("\n").filter((line) => line.length >= 160);
  if (longLines.length >= 3) {
    addFinding(findings, "advisory", filePath, "長い行が多く、AI と人の両方にとって読み解きにくい可能性があります。");
  }

  if (filePath === "docs/traceability/intents/in-intent-004-traceability-check-gate.md") {
    if (!content.includes("docs/product/vision.md")) {
      addFinding(findings, "blocking", filePath, "Traceability チェック intent に product vision 参照がありません。");
    }
  }
}

function addRequestFindings(findings, requestAnalysis) {
  if (requestAnalysis.mode === "docs_review") {
    return;
  }

  if (requestAnalysis.mode === "top_level_source_change") {
    addFinding(
      findings,
      "warning",
      "request_input",
      "この要求は通常の機能追加ではなく、上位正本変更モードとして扱うのが適切です。"
    );
    addFinding(
      findings,
      "advisory",
      "request_input",
      "影響候補: docs/product/vision.md, docs/traceability/value-streams/, docs/traceability/intents/, docs/traceability/feature-proposals/, docs/traceability/implementation-specs/, docs/product/expected-outputs/, docs/operations/, docs/decisions/."
    );
    if (requestAnalysis.implementationIntentDetected) {
      addFinding(
        findings,
        "advisory",
        "request_input",
        "上位正本の変更を整理した後に、通常の Requirement -> Development ゲートを新しい正本で再実行してください。"
      );
    }
  }
}

function buildReport(findings, requestAnalysis) {
  const ordered = [...findings].sort((a, b) => {
    const severityDiff = FINDING_ORDER[a.severity] - FINDING_ORDER[b.severity];
    if (severityDiff !== 0) return severityDiff;
    return a.file.localeCompare(b.file);
  });

  const counts = {
    blocking: ordered.filter((item) => item.severity === "blocking").length,
    warning: ordered.filter((item) => item.severity === "warning").length,
    advisory: ordered.filter((item) => item.severity === "advisory").length,
  };

  const status = counts.blocking > 0 ? "blocking" : counts.warning > 0 ? "warning" : "pass";
  const lines = [];
  lines.push("# Traceability Check Report");
  lines.push("");
  lines.push(`- status: ${status}`);
  lines.push(`- mode: ${requestAnalysis.mode}`);
  lines.push(`- blocking_errors: ${counts.blocking}`);
  lines.push(`- warnings: ${counts.warning}`);
  lines.push(`- advisories: ${counts.advisory}`);
  lines.push(`- auto_fixes_applied: none`);
  if (requestText.trim()) {
    lines.push(`- request: ${requestText.trim()}`);
  }
  if (requestAnalysis.reasons?.length) {
    lines.push(`- mode_reasons: ${requestAnalysis.reasons.join(", ")}`);
  }
  lines.push("");

  if (ordered.length === 0) {
    lines.push("問題は見つかりませんでした。");
    return lines.join("\n");
  }

  for (const severity of ["blocking", "warning", "advisory"]) {
    const items = ordered.filter((item) => item.severity === severity);
    if (items.length === 0) continue;
    lines.push(`## ${severity}`);
    for (const item of items) {
      lines.push(`- [${item.file}] ${item.message}`);
    }
    lines.push("");
  }

  lines.push("## next_actions");
  if (requestAnalysis.mode === "top_level_source_change") {
    lines.push("- まず上位正本変更として影響資産を更新し、その後で通常ゲートを再実行してください。");
  } else if (counts.blocking > 0) {
    lines.push("- blocking error を解消してから次のゲートへ進めてください。");
  } else if (counts.warning > 0) {
    lines.push("- warning を確認し、必要な文書補完やレビュー観点追加を行ってください。");
  } else {
    lines.push("- このまま次のゲートへ進めます。");
  }

  return lines.join("\n");
}

function main() {
  const findings = [];
  const registryPath = "docs/traceability/intent-registry.md";
  const traceabilityFiles = collectFiles("docs/traceability")
    .filter((filePath) => filePath.endsWith(".md"))
    .filter((filePath) => !filePath.endsWith("/_template.md"));
  const requestAnalysis = classifyRequestMode(requestText);

  const intentMap = intentFilesById();
  checkRegistry(findings, registryPath, intentMap);

  for (const filePath of traceabilityFiles) {
    checkDocFile(findings, filePath);
  }

  addRequestFindings(findings, requestAnalysis);

  const report = buildReport(findings, requestAnalysis);
  console.log(report);

  if (failOnBlocking && findings.some((item) => item.severity === "blocking")) {
    process.exitCode = 1;
  }
}

main();

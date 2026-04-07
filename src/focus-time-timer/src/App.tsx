import { useEffect, useMemo, useRef, useState } from "react";

const DEFAULT_MINUTES = 25;

type TimerPhase = "beforeStart" | "running" | "paused" | "done";

function formatRemaining(totalSeconds: number): string {
  const clamped = Math.max(totalSeconds, 0);
  const minutes = Math.floor(clamped / 60);
  const seconds = clamped % 60;
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

export default function App() {
  const [minutesInput, setMinutesInput] = useState(String(DEFAULT_MINUTES));
  const [phase, setPhase] = useState<TimerPhase>("beforeStart");
  const [remainingSeconds, setRemainingSeconds] = useState(DEFAULT_MINUTES * 60);
  const [targetTimeMs, setTargetTimeMs] = useState<number | null>(null);
  const intervalRef = useRef<number | null>(null);
  const audioContextRef = useRef<AudioContext | null>(null);

  const minutesValue = useMemo(() => {
    const parsed = Number(minutesInput);
    if (!Number.isFinite(parsed)) {
      return null;
    }

    return parsed;
  }, [minutesInput]);

  const isMinutesValid = minutesValue !== null && Number.isInteger(minutesValue) && minutesValue > 0 && minutesValue <= 180;

  useEffect(() => {
    if (phase !== "running" || targetTimeMs === null) {
      return;
    }

    const updateRemaining = () => {
      const nextRemaining = Math.max(0, Math.ceil((targetTimeMs - Date.now()) / 1000));
      setRemainingSeconds(nextRemaining);

      if (nextRemaining <= 0) {
        setPhase("done");
        setTargetTimeMs(null);
      }
    };

    updateRemaining();
    intervalRef.current = window.setInterval(updateRemaining, 1000);

    return () => {
      if (intervalRef.current !== null) {
        window.clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    };
  }, [phase, targetTimeMs]);

  useEffect(() => {
    if (phase !== "done") {
      return;
    }

    void playAlarm(audioContextRef);
  }, [phase]);

  const handleStart = async () => {
    if (!isMinutesValid || minutesValue === null) {
      return;
    }

    const totalSeconds = minutesValue * 60;
    setRemainingSeconds(totalSeconds);
    setPhase("running");
    setTargetTimeMs(Date.now() + totalSeconds * 1000);
    await ensureAudioContext(audioContextRef);
  };

  const handleStop = () => {
    setPhase("paused");
    setTargetTimeMs(null);
  };

  const handleReset = () => {
    if (intervalRef.current !== null) {
      window.clearInterval(intervalRef.current);
      intervalRef.current = null;
    }

    const nextMinutes = isMinutesValid && minutesValue !== null ? minutesValue : DEFAULT_MINUTES;
    setRemainingSeconds(nextMinutes * 60);
    setTargetTimeMs(null);
    setPhase("beforeStart");
  };

  const statusLabel =
    phase === "beforeStart"
      ? "開始前"
      : phase === "running"
        ? "使用中"
        : phase === "paused"
          ? "停止中"
          : "終了後";
  const remainingText = formatRemaining(remainingSeconds);

  return (
    <main className="app-shell">
      <section className="timer-card">
        <h1 className="title">Focus Time Timer</h1>
        <p className="subtitle">新しいデモ環境</p>

        <div className="status-box">
          <span className="status-label">現在状態</span>
          <strong className="status-value">{statusLabel}</strong>
        </div>

        <label className="field">
          <span className="field-label">時間（分）</span>
          <input
            className="minutes-input"
            type="number"
            min={1}
            max={180}
            step={1}
            value={minutesInput}
            onChange={(event) => setMinutesInput(event.target.value)}
            disabled={phase === "running"}
          />
        </label>

        {!isMinutesValid && <p className="validation-message">1 から 180 までの整数を入力してください。</p>}

        <div className="remaining-box" aria-live="polite">
          <span className="remaining-label">残り時間</span>
          <strong className="remaining-value">{remainingText}</strong>
        </div>

        <div className="button-row">
          <button className="primary-button" type="button" onClick={handleStart} disabled={!isMinutesValid || phase === "running"}>
            開始
          </button>
          <button className="secondary-button" type="button" onClick={handleStop} disabled={phase !== "running"}>
            停止
          </button>
          <button className="secondary-button" type="button" onClick={handleReset}>
            リセット
          </button>
        </div>

        {phase === "done" && (
          <div className="message-box" role="status">
            <p className="message-title">終了しました</p>
            <p className="message-body">休憩時間です</p>
          </div>
        )}
      </section>
    </main>
  );
}

async function ensureAudioContext(audioContextRef: React.MutableRefObject<AudioContext | null>) {
  if (typeof window === "undefined" || !("AudioContext" in window || "webkitAudioContext" in window)) {
    return;
  }

  const AudioContextCtor = window.AudioContext ?? (window as typeof window & { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
  if (!AudioContextCtor) {
    return;
  }

  if (audioContextRef.current === null) {
    audioContextRef.current = new AudioContextCtor();
  }

  if (audioContextRef.current.state === "suspended") {
    await audioContextRef.current.resume();
  }
}

async function playAlarm(audioContextRef: React.MutableRefObject<AudioContext | null>) {
  const audioContext = audioContextRef.current;
  if (!audioContext) {
    return;
  }

  if (audioContext.state === "suspended") {
    await audioContext.resume();
  }

  const now = audioContext.currentTime;
  const gainNode = audioContext.createGain();
  gainNode.connect(audioContext.destination);
  gainNode.gain.setValueAtTime(0.0001, now);
  gainNode.gain.exponentialRampToValueAtTime(0.25, now + 0.02);
  gainNode.gain.exponentialRampToValueAtTime(0.0001, now + 0.7);

  const oscillator = audioContext.createOscillator();
  oscillator.type = "square";
  oscillator.frequency.setValueAtTime(880, now);
  oscillator.connect(gainNode);
  oscillator.start(now);
  oscillator.stop(now + 0.7);
}

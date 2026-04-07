import { useEffect, useState } from "react";

function getSecondHandRotation(date: Date): number {
  return date.getSeconds() * 6;
}

function formatDigitalTime(date: Date): string {
  return new Intl.DateTimeFormat("ja-JP", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  }).format(date);
}

export default function App() {
  const [now, setNow] = useState(() => new Date());

  useEffect(() => {
    const timerId = window.setInterval(() => {
      setNow(new Date());
    }, 1000);

    return () => {
      window.clearInterval(timerId);
    };
  }, []);

  const secondHandRotation = getSecondHandRotation(now);
  const digitalTime = formatDigitalTime(now);

  return (
    <main className="app-shell">
      <section className="clock-card">
        <p className="eyebrow">Demo Clock</p>
        <h1 className="title">秒針だけのアナログ時計</h1>
        <p className="subtitle">現在時刻の秒だけをシンプルに表示します。</p>

        <div className="clock-frame" role="img" aria-label={`現在時刻 ${digitalTime} のアナログ時計`}>
          <div className="clock-face">
            <div className="tick tick-12" />
            <div className="tick tick-3" />
            <div className="tick tick-6" />
            <div className="tick tick-9" />
            <div className="second-hand" style={{ transform: `translateX(-50%) rotate(${secondHandRotation}deg)` }} />
            <div className="clock-center" />
          </div>
        </div>

        <div className="readout-box" aria-live="polite">
          <span className="readout-label">現在時刻</span>
          <strong className="readout-value">{digitalTime}</strong>
        </div>
      </section>
    </main>
  );
}

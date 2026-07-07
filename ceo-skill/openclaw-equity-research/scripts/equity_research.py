#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


DISCLAIMER = (
    "This is research assistance, not financial advice. Verify data and consult a qualified "
    "professional before making investment decisions."
)


@dataclass
class PriceSnapshot:
    ticker: str
    generated_at: str
    company_name: str | None
    sector: str | None
    industry: str | None
    currency: str | None
    market_cap: float | None
    last_close: float | None
    previous_close: float | None
    day_change_pct: float | None
    return_1m_pct: float | None
    return_3m_pct: float | None
    return_6m_pct: float | None
    avg_volume_20d: float | None
    latest_volume: float | None
    sma20: float | None
    sma50: float | None
    sma200: float | None
    rsi14: float | None
    technical_view: str
    data_warnings: list[str]


def now_utc() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")


def safe_float(value: Any) -> float | None:
    try:
        if value is None:
            return None
        out = float(value)
        if math.isnan(out) or math.isinf(out):
            return None
        return out
    except Exception:
        return None


def pct_change(new: float | None, old: float | None) -> float | None:
    if new is None or old in (None, 0):
        return None
    return (new - old) / old * 100


def fmt(value: Any, digits: int = 2) -> str:
    num = safe_float(value)
    if num is None:
        return "n/a"
    return f"{num:,.{digits}f}"


def fmt_pct(value: Any) -> str:
    num = safe_float(value)
    if num is None:
        return "n/a"
    return f"{num:+.2f}%"


def simple_rsi(closes: list[float], period: int = 14) -> float | None:
    if len(closes) <= period:
        return None
    gains: list[float] = []
    losses: list[float] = []
    for prev, cur in zip(closes[-period - 1 : -1], closes[-period:]):
        delta = cur - prev
        gains.append(max(delta, 0))
        losses.append(abs(min(delta, 0)))
    avg_gain = sum(gains) / period
    avg_loss = sum(losses) / period
    if avg_loss == 0:
        return 100.0
    rs = avg_gain / avg_loss
    return 100 - (100 / (1 + rs))


def moving_average(values: list[float], window: int) -> float | None:
    if len(values) < window:
        return None
    return sum(values[-window:]) / window


def technical_view(last: float | None, sma20: float | None, sma50: float | None, sma200: float | None, rsi: float | None) -> str:
    score = 0
    if last is not None and sma20 is not None and last > sma20:
        score += 1
    if sma20 is not None and sma50 is not None and sma20 > sma50:
        score += 1
    if sma50 is not None and sma200 is not None and sma50 > sma200:
        score += 1
    if rsi is not None and 45 <= rsi <= 70:
        score += 1
    if rsi is not None and rsi > 75:
        score -= 1
    if score >= 3:
        return "Constructive"
    if score <= 1:
        return "Weak or mixed"
    return "Neutral"


def load_yfinance_snapshot(ticker: str) -> tuple[PriceSnapshot, list[dict[str, str]]]:
    warnings: list[str] = []
    try:
        import yfinance as yf  # type: ignore
    except Exception as exc:
        raise SystemExit(f"yfinance is required for live mode: {exc}")

    obj = yf.Ticker(ticker)
    try:
        hist = obj.history(period="1y", interval="1d", auto_adjust=False).reset_index()
    except Exception as exc:
        raise SystemExit(f"failed to fetch history for {ticker}: {exc}")

    if hist.empty:
        raise SystemExit(f"no price history returned for {ticker}")

    info: dict[str, Any] = {}
    try:
        info = obj.get_info() or {}
    except Exception as exc:
        warnings.append(f"company profile unavailable: {exc}")

    closes = [safe_float(x) for x in hist["Close"].tolist()]
    closes = [x for x in closes if x is not None]
    volumes = [safe_float(x) for x in hist["Volume"].tolist()]
    volumes = [x for x in volumes if x is not None]

    last = closes[-1] if closes else None
    prev = closes[-2] if len(closes) > 1 else None
    sma20 = moving_average(closes, 20)
    sma50 = moving_average(closes, 50)
    sma200 = moving_average(closes, 200)
    rsi = simple_rsi(closes)

    def trailing_return(days: int) -> float | None:
        if len(closes) <= days:
            return None
        return pct_change(closes[-1], closes[-days - 1])

    news: list[dict[str, str]] = []
    try:
        for item in (obj.news or [])[:8]:
            content = item.get("content") or {}
            title = content.get("title") or item.get("title") or ""
            summary = content.get("summary") or item.get("summary") or ""
            url = (
                (content.get("canonicalUrl") or {}).get("url")
                or (content.get("clickThroughUrl") or {}).get("url")
                or item.get("link")
                or ""
            )
            if title:
                news.append({"title": title, "summary": summary, "url": url})
    except Exception as exc:
        warnings.append(f"news unavailable: {exc}")

    snapshot = PriceSnapshot(
        ticker=ticker.upper(),
        generated_at=now_utc(),
        company_name=info.get("longName") or info.get("shortName"),
        sector=info.get("sector"),
        industry=info.get("industry"),
        currency=info.get("currency"),
        market_cap=safe_float(info.get("marketCap")),
        last_close=last,
        previous_close=prev,
        day_change_pct=pct_change(last, prev),
        return_1m_pct=trailing_return(21),
        return_3m_pct=trailing_return(63),
        return_6m_pct=trailing_return(126),
        avg_volume_20d=(sum(volumes[-20:]) / min(len(volumes), 20)) if volumes else None,
        latest_volume=volumes[-1] if volumes else None,
        sma20=sma20,
        sma50=sma50,
        sma200=sma200,
        rsi14=rsi,
        technical_view=technical_view(last, sma20, sma50, sma200, rsi),
        data_warnings=warnings,
    )
    return snapshot, news


def template_snapshot(ticker: str) -> tuple[PriceSnapshot, list[dict[str, str]]]:
    return PriceSnapshot(
        ticker=ticker.upper(),
        generated_at=now_utc(),
        company_name=None,
        sector=None,
        industry=None,
        currency=None,
        market_cap=None,
        last_close=None,
        previous_close=None,
        day_change_pct=None,
        return_1m_pct=None,
        return_3m_pct=None,
        return_6m_pct=None,
        avg_volume_20d=None,
        latest_volume=None,
        sma20=None,
        sma50=None,
        sma200=None,
        rsi14=None,
        technical_view="Not assessed",
        data_warnings=["template mode: no market data fetched"],
    ), []


def render_memo(snapshot: PriceSnapshot, news: list[dict[str, str]]) -> str:
    title_name = snapshot.company_name or snapshot.ticker
    news_block = "\n".join(
        f"- {item['title']}" + (f" ({item['url']})" if item.get("url") else "")
        for item in news[:5]
    ) or "- No recent headlines fetched in this run."
    warnings = "\n".join(f"- {item}" for item in snapshot.data_warnings) or "- None from the data pull."

    return f"""# {snapshot.ticker} Equity Research Memo

## Snapshot
- Company: {title_name}
- Sector / industry: {snapshot.sector or "n/a"} / {snapshot.industry or "n/a"}
- Data timestamp: {snapshot.generated_at}
- Currency: {snapshot.currency or "n/a"}
- Last close: {fmt(snapshot.last_close)}
- Market cap: {fmt(snapshot.market_cap, 0)}
- 1D / 1M / 3M / 6M return: {fmt_pct(snapshot.day_change_pct)} / {fmt_pct(snapshot.return_1m_pct)} / {fmt_pct(snapshot.return_3m_pct)} / {fmt_pct(snapshot.return_6m_pct)}
- Technical view: {snapshot.technical_view}

## Thesis
Write the research thesis here. Separate what is known from what must be verified.

## Evidence
| Area | Evidence | Source / timestamp | Interpretation |
|---|---|---|---|
| Price | Last close {fmt(snapshot.last_close)}, 1M return {fmt_pct(snapshot.return_1m_pct)} | yfinance pull at {snapshot.generated_at} | Establishes recent market posture. |
| Trend | SMA20 {fmt(snapshot.sma20)}, SMA50 {fmt(snapshot.sma50)}, SMA200 {fmt(snapshot.sma200)}, RSI14 {fmt(snapshot.rsi14)} | computed from daily history | Technical posture: {snapshot.technical_view}. |
| Volume | Latest volume {fmt(snapshot.latest_volume, 0)}, 20D avg {fmt(snapshot.avg_volume_20d, 0)} | computed from daily history | Check liquidity and abnormal activity. |

## Market Data And Technical Setup
- Last close: {fmt(snapshot.last_close)}
- Previous close: {fmt(snapshot.previous_close)}
- Day change: {fmt_pct(snapshot.day_change_pct)}
- SMA20 / SMA50 / SMA200: {fmt(snapshot.sma20)} / {fmt(snapshot.sma50)} / {fmt(snapshot.sma200)}
- RSI14: {fmt(snapshot.rsi14)}
- Volume vs 20D average: {fmt(snapshot.latest_volume, 0)} vs {fmt(snapshot.avg_volume_20d, 0)}

## Company And Fundamentals
- Business description: add from filings, investor relations, or reliable company profile.
- Revenue drivers: add segment/product/geography context.
- Financial quality: add growth, margins, free cash flow, balance sheet, dilution, and capital allocation.

## Catalysts
Recent headlines from this run:
{news_block}

Add earnings date, product launches, regulatory events, macro drivers, and analyst estimate changes when available.

## Valuation Frame
- Base case: define revenue/margin/multiple or cash-flow assumptions.
- Bull case: define what has to go right.
- Bear case: define downside assumptions.
- Key assumptions: list the variables that matter most.

## Risks And Falsification
- What would make the thesis wrong?
- What operating metric should be monitored first?
- What price/technical level would invalidate the setup?
- What balance sheet or liquidity risk matters?

## Monitoring Checklist
- Next earnings date and guideposts.
- Revenue growth, gross margin, operating margin, free cash flow.
- Estimate revisions and management commentary.
- Sector/macro indicators.
- Price trend, volume, SMA50/SMA200, RSI regime.

## Research Limits
{warnings}

{DISCLAIMER}
"""


def write_artifacts(snapshot: PriceSnapshot, news: list[dict[str, str]], out_dir: Path) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    stem = snapshot.ticker.lower().replace(".", "-")
    md_path = out_dir / f"{stem}-equity-research.md"
    json_path = out_dir / f"{stem}-equity-research.json"
    md_path.write_text(render_memo(snapshot, news), encoding="utf-8")
    json_path.write_text(
        json.dumps({"snapshot": asdict(snapshot), "news": news, "disclaimer": DISCLAIMER}, indent=2),
        encoding="utf-8",
    )
    return md_path


def render_watchlist(snapshots: list[PriceSnapshot]) -> str:
    rows = []
    for item in snapshots:
        rows.append(
            f"| {item.ticker} | {item.company_name or 'n/a'} | {fmt_pct(item.return_1m_pct)} | "
            f"{fmt_pct(item.return_3m_pct)} | {fmt(item.rsi14)} | {item.technical_view} | {item.sector or 'n/a'} |"
        )
    return f"""# Equity Watchlist Triage

- Generated: {now_utc()}
- Tickers: {", ".join(item.ticker for item in snapshots)}

| Ticker | Company | 1M return | 3M return | RSI14 | Technical view | Sector |
|---|---|---:|---:|---:|---|---|
{chr(10).join(rows)}

## Next Research Steps
- Pick the names with the clearest variant perception.
- Add fundamentals, valuation, catalysts, and risk checks before forming a research view.
- Verify current data and news before any decision.

{DISCLAIMER}
"""


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate lightweight equity research artifacts.")
    parser.add_argument("tickers", nargs="*", help="Ticker symbols, e.g. AAPL TSLA NVDA")
    parser.add_argument("--out", default="reports", help="Output directory")
    parser.add_argument("--mode", choices=["memo", "watchlist"], default="memo")
    parser.add_argument("--template", action="store_true", help="Generate offline template(s) without fetching data")
    args = parser.parse_args()

    tickers = [item.upper() for item in args.tickers if item.strip()]
    if not tickers:
        tickers = ["TICKER"] if args.template else []
    if not tickers:
        parser.error("provide at least one ticker or use --template")

    out_dir = Path(args.out)
    snapshots: list[PriceSnapshot] = []
    for ticker in tickers:
        snapshot, news = template_snapshot(ticker) if args.template else load_yfinance_snapshot(ticker)
        snapshots.append(snapshot)
        if args.mode == "memo":
            path = write_artifacts(snapshot, news, out_dir)
            print(path)

    if args.mode == "watchlist":
        out_dir.mkdir(parents=True, exist_ok=True)
        path = out_dir / "watchlist-equity-research.md"
        path.write_text(render_watchlist(snapshots), encoding="utf-8")
        print(path)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

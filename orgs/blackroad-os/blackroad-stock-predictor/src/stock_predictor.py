#!/usr/bin/env python3
"""BlackRoad Stock Predictor - Production Module.

Stock market technical analysis using OHLCV price bars,
Simple Moving Average crossover signals, and momentum indicators.
"""

import argparse
import json
import sqlite3
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import List, Optional

RED     = "\033[0;31m"
GREEN   = "\033[0;32m"
YELLOW  = "\033[1;33m"
CYAN    = "\033[0;36m"
BLUE    = "\033[0;34m"
MAGENTA = "\033[0;35m"
BOLD    = "\033[1m"
DIM     = "\033[2m"
NC      = "\033[0m"

DB_PATH = Path.home() / ".blackroad" / "stock_predictor.db"


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass
class Stock:
    ticker: str
    name: str
    sector: str
    exchange: str = "NYSE"
    created_at: str = ""
    id: Optional[int] = None

    def __post_init__(self):
        if not self.created_at:
            self.created_at = datetime.now().isoformat()


@dataclass
class PriceBar:
    ticker: str
    bar_date: str
    open_price: float
    high_price: float
    low_price: float
    close_price: float
    volume: int
    recorded_at: str = ""
    id: Optional[int] = None

    def __post_init__(self):
        if not self.recorded_at:
            self.recorded_at = datetime.now().isoformat()


@dataclass
class TrendSignal:
    ticker: str
    signal_type: str    # BUY | SELL | HOLD | NEUTRAL
    indicator: str      # SMA_CROSS | MOMENTUM | INSUFFICIENT_DATA
    strength: float     # 0.0 – 1.0
    price_at_signal: float
    rationale: str
    sma_short: float = 0.0
    sma_long: float = 0.0
    momentum_pct: float = 0.0
    generated_at: str = ""
    id: Optional[int] = None

    def __post_init__(self):
        if not self.generated_at:
            self.generated_at = datetime.now().isoformat()


# ---------------------------------------------------------------------------
# Database / Business Logic
# ---------------------------------------------------------------------------

class StockPredictor:
    """Stock market technical analysis with SMA crossover and momentum signals."""

    def __init__(self, db_path: Path = DB_PATH):
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _conn(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL")
        return conn

    def _init_db(self):
        with self._conn() as conn:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS stocks (
                    id         INTEGER PRIMARY KEY AUTOINCREMENT,
                    ticker     TEXT UNIQUE NOT NULL,
                    name       TEXT NOT NULL,
                    sector     TEXT NOT NULL,
                    exchange   TEXT DEFAULT 'NYSE',
                    created_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS price_bars (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    ticker      TEXT NOT NULL,
                    bar_date    TEXT NOT NULL,
                    open_price  REAL NOT NULL,
                    high_price  REAL NOT NULL,
                    low_price   REAL NOT NULL,
                    close_price REAL NOT NULL,
                    volume      INTEGER NOT NULL,
                    recorded_at TEXT NOT NULL,
                    UNIQUE (ticker, bar_date)
                );
                CREATE TABLE IF NOT EXISTS signals (
                    id              INTEGER PRIMARY KEY AUTOINCREMENT,
                    ticker          TEXT NOT NULL,
                    signal_type     TEXT NOT NULL,
                    indicator       TEXT NOT NULL,
                    strength        REAL NOT NULL,
                    price_at_signal REAL NOT NULL,
                    rationale       TEXT NOT NULL,
                    sma_short       REAL DEFAULT 0.0,
                    sma_long        REAL DEFAULT 0.0,
                    momentum_pct    REAL DEFAULT 0.0,
                    generated_at    TEXT NOT NULL
                );
                CREATE INDEX IF NOT EXISTS idx_bars_ticker ON price_bars(ticker, bar_date);
                CREATE INDEX IF NOT EXISTS idx_sigs_ticker ON signals(ticker, generated_at);
            """)

    def add_stock(self, ticker: str, name: str, sector: str,
                  exchange: str = "NYSE") -> Stock:
        """Register a stock for tracking and technical analysis."""
        s = Stock(ticker=ticker.upper(), name=name,
                  sector=sector, exchange=exchange)
        with self._conn() as conn:
            conn.execute(
                "INSERT OR IGNORE INTO stocks "
                "(ticker, name, sector, exchange, created_at) VALUES (?,?,?,?,?)",
                (s.ticker, s.name, s.sector, s.exchange, s.created_at)
            )
        return s

    def record_price(self, ticker: str, open_p: float, high: float,
                     low: float, close: float, volume: int,
                     bar_date: Optional[str] = None) -> PriceBar:
        """Record an OHLCV price bar for a stock."""
        bar = PriceBar(
            ticker=ticker.upper(),
            bar_date=bar_date or datetime.now().date().isoformat(),
            open_price=open_p, high_price=high,
            low_price=low, close_price=close, volume=volume,
        )
        with self._conn() as conn:
            conn.execute(
                "INSERT OR REPLACE INTO price_bars "
                "(ticker, bar_date, open_price, high_price, low_price, "
                "close_price, volume, recorded_at) VALUES (?,?,?,?,?,?,?,?)",
                (bar.ticker, bar.bar_date, bar.open_price, bar.high_price,
                 bar.low_price, bar.close_price, bar.volume, bar.recorded_at)
            )
        return bar

    def _sma(self, closes: list, period: int) -> Optional[float]:
        """Compute SMA from a list of closing prices (most-recent first)."""
        if len(closes) < period:
            return None
        return round(sum(closes[:period]) / period, 4)

    def detect_signal(self, ticker: str) -> TrendSignal:
        """Analyse price history and emit a BUY / SELL / HOLD signal."""
        ticker = ticker.upper()
        with self._conn() as conn:
            bars = conn.execute(
                "SELECT * FROM price_bars WHERE ticker=? "
                "ORDER BY bar_date DESC LIMIT 50",
                (ticker,)
            ).fetchall()

        if not bars:
            return TrendSignal(ticker=ticker, signal_type="NEUTRAL",
                               indicator="INSUFFICIENT_DATA", strength=0.0,
                               price_at_signal=0.0,
                               rationale="No price data available.")

        closes = [b["close_price"] for b in bars]
        latest = closes[0]

        sma10 = self._sma(closes, 10)
        sma20 = self._sma(closes, 20)

        if sma10 is None or sma20 is None:
            momentum = (closes[0] - closes[-1]) / closes[-1] * 100 if closes[-1] else 0.0
            if momentum > 3.0:
                stype, strength = "BUY",  min(1.0, momentum / 15.0)
                rationale = f"Positive momentum {momentum:+.2f}% over {len(closes)} bars."
            elif momentum < -3.0:
                stype, strength = "SELL", min(1.0, abs(momentum) / 15.0)
                rationale = f"Negative momentum {momentum:+.2f}% over {len(closes)} bars."
            else:
                stype, strength, momentum = "HOLD", 0.5, momentum
                rationale = f"Momentum {momentum:+.2f}% — within neutral range."
            sig = TrendSignal(ticker=ticker, signal_type=stype,
                              indicator="MOMENTUM", strength=round(strength, 3),
                              price_at_signal=latest, rationale=rationale,
                              momentum_pct=round(momentum, 4))
        else:
            momentum = (closes[0] - closes[min(19, len(closes) - 1)]) / closes[min(19, len(closes) - 1)] * 100
            if sma10 > sma20 * 1.015 and momentum > 1.5:
                stype   = "BUY"
                strength = min(1.0, (sma10 / sma20 - 1.0) * 20 + momentum / 20.0)
                rationale = (f"SMA(10)={sma10:.2f} above SMA(20)={sma20:.2f} "
                             f"[+{(sma10/sma20-1)*100:.2f}%]; momentum={momentum:+.2f}%")
            elif sma10 < sma20 * 0.985 and momentum < -1.5:
                stype   = "SELL"
                strength = min(1.0, (1.0 - sma10 / sma20) * 20 + abs(momentum) / 20.0)
                rationale = (f"SMA(10)={sma10:.2f} below SMA(20)={sma20:.2f} "
                             f"[{(sma10/sma20-1)*100:.2f}%]; momentum={momentum:+.2f}%")
            else:
                stype, strength = "HOLD", 0.5
                rationale = (f"SMA(10)={sma10:.2f} vs SMA(20)={sma20:.2f}; "
                             "awaiting decisive crossover.")
            sig = TrendSignal(ticker=ticker, signal_type=stype,
                              indicator="SMA_CROSS", strength=round(strength, 3),
                              price_at_signal=latest, rationale=rationale,
                              sma_short=sma10, sma_long=sma20,
                              momentum_pct=round(momentum, 4))

        with self._conn() as conn:
            cur = conn.execute(
                "INSERT INTO signals (ticker, signal_type, indicator, strength, "
                "price_at_signal, rationale, sma_short, sma_long, momentum_pct, "
                "generated_at) VALUES (?,?,?,?,?,?,?,?,?,?)",
                (sig.ticker, sig.signal_type, sig.indicator, sig.strength,
                 sig.price_at_signal, sig.rationale, sig.sma_short,
                 sig.sma_long, sig.momentum_pct, sig.generated_at)
            )
            sig.id = cur.lastrowid
        return sig

    def list_stocks(self) -> List[dict]:
        """List tracked stocks with most-recent price bar."""
        with self._conn() as conn:
            rows = conn.execute("""
                SELECT s.*,
                       pb.close_price AS latest_price,
                       pb.bar_date    AS latest_date,
                       pb.volume      AS latest_volume
                FROM stocks s
                LEFT JOIN price_bars pb
                  ON s.ticker = pb.ticker
                 AND pb.bar_date = (
                     SELECT MAX(bar_date) FROM price_bars p2
                     WHERE p2.ticker = s.ticker
                 )
                ORDER BY s.ticker
            """).fetchall()
        return [dict(r) for r in rows]

    def get_signals(self, ticker: Optional[str] = None,
                    limit: int = 20) -> List[dict]:
        """Retrieve recent trading signals, optionally filtered by ticker."""
        with self._conn() as conn:
            if ticker:
                rows = conn.execute(
                    "SELECT * FROM signals WHERE ticker=? "
                    "ORDER BY generated_at DESC LIMIT ?",
                    (ticker.upper(), limit)
                ).fetchall()
            else:
                rows = conn.execute(
                    "SELECT * FROM signals ORDER BY generated_at DESC LIMIT ?",
                    (limit,)
                ).fetchall()
        return [dict(r) for r in rows]

    def export_report(self, output_path: str = "stock_report.json") -> str:
        """Export analysis report to JSON."""
        data = {
            "exported_at":    datetime.now().isoformat(),
            "generator":      "BlackRoad Stock Predictor v1.0",
            "stocks":         self.list_stocks(),
            "recent_signals": self.get_signals(limit=100),
        }
        Path(output_path).write_text(json.dumps(data, indent=2))
        return output_path


# ---------------------------------------------------------------------------
# CLI helpers
# ---------------------------------------------------------------------------

def _header(title: str):
    w = 64
    print(f"\n{BOLD}{BLUE}{'━' * w}{NC}")
    print(f"{BOLD}{BLUE}  {title}{NC}")
    print(f"{BOLD}{BLUE}{'━' * w}{NC}")


def _signal_color(stype: str) -> str:
    return {
        "BUY": GREEN + BOLD, "SELL": RED + BOLD,
        "HOLD": YELLOW, "NEUTRAL": DIM,
    }.get(stype, NC)


# ---------------------------------------------------------------------------
# CLI commands
# ---------------------------------------------------------------------------

def cmd_list(args, predictor: StockPredictor):
    stocks = predictor.list_stocks()
    _header("STOCK PREDICTOR — Tracked Securities")
    if not stocks:
        print(f"  {YELLOW}No stocks tracked. Use 'add' to register securities.{NC}\n")
        return
    for s in stocks:
        price_str = (f"{YELLOW}${s['latest_price']:>10.2f}{NC}  [{s['latest_date']}]"
                     if s.get("latest_price") else f"{DIM}No price data{NC}")
        print(f"  {CYAN}{s['ticker']:<8}{NC}  {BOLD}{s['name']:<28}{NC}  "
              f"{DIM}{s['sector']:<16}{NC}  [{s['exchange']}]")
        print(f"           Latest: {price_str}")
        print()


def cmd_add(args, predictor: StockPredictor):
    predictor.add_stock(args.ticker, args.name, args.sector, args.exchange)
    print(f"\n{GREEN}✓ Stock registered:{NC} "
          f"{BOLD}{args.ticker.upper()}{NC} — {args.name} "
          f"[{args.sector}  {args.exchange}]\n")


def cmd_price(args, predictor: StockPredictor):
    bar = predictor.record_price(
        args.ticker, args.open, args.high,
        args.low, args.close, args.volume, args.date,
    )
    change = bar.close_price - bar.open_price
    cc = GREEN if change >= 0 else RED
    print(f"\n{CYAN}✓ Price bar recorded:{NC} "
          f"{BOLD}{args.ticker.upper()}{NC}  [{bar.bar_date}]")
    print(f"  O:{bar.open_price:.2f}  H:{bar.high_price:.2f}  "
          f"L:{bar.low_price:.2f}  C:{bar.close_price:.2f}  "
          f"Vol:{bar.volume:,}  Chg:{cc}{change:+.2f}{NC}\n")


def cmd_analyze(args, predictor: StockPredictor):
    sig = predictor.detect_signal(args.ticker)
    sc  = _signal_color(sig.signal_type)
    _header(f"SIGNAL ANALYSIS — {sig.ticker}")
    print(f"  {DIM}Signal:{NC}          {sc}{sig.signal_type}{NC}  "
          f"(strength: {YELLOW}{sig.strength:.0%}{NC})")
    print(f"  {DIM}Indicator:{NC}       {sig.indicator}")
    print(f"  {DIM}Price at signal:{NC} ${sig.price_at_signal:.4f}")
    if sig.sma_short:
        print(f"  {DIM}SMA(10):{NC}         {sig.sma_short:.4f}")
    if sig.sma_long:
        print(f"  {DIM}SMA(20):{NC}         {sig.sma_long:.4f}")
    if sig.momentum_pct:
        mc = GREEN if sig.momentum_pct >= 0 else RED
        print(f"  {DIM}Momentum:{NC}        {mc}{sig.momentum_pct:+.2f}%{NC}")
    print(f"  {DIM}Rationale:{NC}       {sig.rationale}")
    print(f"  {DIM}Generated:{NC}       {sig.generated_at[:19]}\n")


def cmd_signals(args, predictor: StockPredictor):
    sigs = predictor.get_signals(getattr(args, "ticker", None))
    _header("RECENT TRADING SIGNALS")
    if not sigs:
        print(f"  {YELLOW}No signals yet. Run 'analyze <TICKER>' first.{NC}\n")
        return
    for s in sigs:
        sc = _signal_color(s["signal_type"])
        print(f"  {CYAN}{s['ticker']:<7}{NC}  {sc}{s['signal_type']:<6}{NC}  "
              f"@ {YELLOW}${s['price_at_signal']:>9.2f}{NC}  "
              f"str:{s['strength']:.0%}  "
              f"{DIM}{s['generated_at'][:10]}{NC}")
    print()


def cmd_export(args, predictor: StockPredictor):
    path = predictor.export_report(args.output)
    print(f"\n{GREEN}✓ Report exported to:{NC} {BOLD}{path}{NC}\n")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    predictor = StockPredictor()
    parser = argparse.ArgumentParser(
        prog="stock-predictor",
        description=f"{BOLD}BlackRoad Stock Predictor & Technical Analyzer{NC}",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  %(prog)s add --ticker AAPL --name 'Apple Inc' --sector Technology\n"
            "  %(prog)s price --ticker AAPL --open 185 --high 188 --low 184 "
            "--close 187 --volume 55000000\n"
            "  %(prog)s analyze AAPL\n"
            "  %(prog)s signals --ticker AAPL\n"
        ),
    )
    subs = parser.add_subparsers(dest="command", metavar="COMMAND")
    subs.required = True

    subs.add_parser("list", help="List tracked stocks")

    p = subs.add_parser("add", help="Register a stock for tracking")
    p.add_argument("--ticker",   required=True, metavar="AAPL")
    p.add_argument("--name",     required=True, metavar="\"Apple Inc.\"")
    p.add_argument("--sector",   required=True, metavar="Technology")
    p.add_argument("--exchange", default="NYSE")

    p = subs.add_parser("price", help="Record an OHLCV price bar")
    p.add_argument("--ticker", required=True)
    p.add_argument("--open",   required=True, type=float)
    p.add_argument("--high",   required=True, type=float)
    p.add_argument("--low",    required=True, type=float)
    p.add_argument("--close",  required=True, type=float)
    p.add_argument("--volume", required=True, type=int)
    p.add_argument("--date",   default=None,  metavar="YYYY-MM-DD")

    p = subs.add_parser("analyze", help="Generate trading signal for a stock")
    p.add_argument("ticker", metavar="TICKER")

    p = subs.add_parser("signals", help="Show recent trading signals")
    p.add_argument("--ticker", default=None)

    p = subs.add_parser("export", help="Export analysis report")
    p.add_argument("--output", default="stock_report.json", metavar="FILE")

    args = parser.parse_args()
    {"list": cmd_list, "add": cmd_add, "price": cmd_price,
     "analyze": cmd_analyze, "signals": cmd_signals, "export": cmd_export
     }[args.command](args, predictor)


if __name__ == "__main__":
    main()

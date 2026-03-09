"""
BlackRoad Stock Predictor — Quantitative Technical Analysis Engine
Real financial algorithms: SMA, EMA, RSI, MACD, Bollinger Bands,
Stochastic, ATR, OBV, VWAP, Support/Resistance, Sharpe, Kelly, Drawdown.
"""

import argparse
import math
import sqlite3
import statistics
from dataclasses import dataclass, field
from datetime import date, datetime
from typing import List, Optional, Tuple


# ── ANSI colours ────────────────────────────────────────────────────────────
GREEN  = "\033[32m"
RED    = "\033[31m"
YELLOW = "\033[33m"
CYAN   = "\033[36m"
BOLD   = "\033[1m"
RESET  = "\033[0m"

DB_PATH = "stock_analytics.db"


# ── Dataclasses ──────────────────────────────────────────────────────────────
@dataclass
class PriceBar:
    symbol: str
    date: str
    open: float
    high: float
    low: float
    close: float
    volume: float


@dataclass
class MovingAverageResult:
    period: int
    values: List[float]          # aligned to tail of input


@dataclass
class RSIResult:
    period: int
    values: List[float]          # RSI [0..100]
    latest: float


@dataclass
class MACDResult:
    macd_line: List[float]
    signal_line: List[float]
    histogram: List[float]
    latest_macd: float
    latest_signal: float
    latest_histogram: float


@dataclass
class BollingerBand:
    period: int
    std_dev: float
    upper: List[float]
    middle: List[float]
    lower: List[float]
    latest_upper: float
    latest_middle: float
    latest_lower: float
    bandwidth: float             # (upper - lower) / middle


@dataclass
class SupportResistance:
    pivot: float
    r1: float
    r2: float
    r3: float
    s1: float
    s2: float
    s3: float


@dataclass
class TradingSignal:
    symbol: str
    date: str
    signal: str          # BUY | SELL | NEUTRAL
    source: str          # RSI | MACD | BB | CROSS
    strength: float      # 0..1
    price: float
    note: str = ""


# ── Database ─────────────────────────────────────────────────────────────────
def get_conn(path: str = DB_PATH) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    _init_schema(conn)
    return conn


def _init_schema(conn: sqlite3.Connection) -> None:
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS price_bars (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            symbol  TEXT    NOT NULL,
            date    TEXT    NOT NULL,
            open    REAL    NOT NULL,
            high    REAL    NOT NULL,
            low     REAL    NOT NULL,
            close   REAL    NOT NULL,
            volume  REAL    NOT NULL DEFAULT 0,
            UNIQUE(symbol, date)
        );
        CREATE TABLE IF NOT EXISTS signals (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            symbol   TEXT NOT NULL,
            date     TEXT NOT NULL,
            signal   TEXT NOT NULL,
            source   TEXT NOT NULL,
            strength REAL NOT NULL,
            price    REAL NOT NULL,
            note     TEXT
        );
        CREATE INDEX IF NOT EXISTS idx_pb_sym_date ON price_bars(symbol, date);
    """)
    conn.commit()


def load_bars(conn: sqlite3.Connection, symbol: str) -> List[PriceBar]:
    rows = conn.execute(
        "SELECT * FROM price_bars WHERE symbol=? ORDER BY date", (symbol,)
    ).fetchall()
    return [PriceBar(**dict(r)) for r in rows]


def insert_bar(conn: sqlite3.Connection, bar: PriceBar) -> None:
    conn.execute(
        """INSERT OR REPLACE INTO price_bars
           (symbol,date,open,high,low,close,volume) VALUES (?,?,?,?,?,?,?)""",
        (bar.symbol, bar.date, bar.open, bar.high, bar.low, bar.close, bar.volume),
    )
    conn.commit()


def save_signal(conn: sqlite3.Connection, sig: TradingSignal) -> None:
    conn.execute(
        """INSERT INTO signals (symbol,date,signal,source,strength,price,note)
           VALUES (?,?,?,?,?,?,?)""",
        (sig.symbol, sig.date, sig.signal, sig.source, sig.strength, sig.price, sig.note),
    )
    conn.commit()


# ── Core Indicators ──────────────────────────────────────────────────────────

def sma(prices: List[float], period: int) -> List[float]:
    """Simple Moving Average over `period` bars."""
    if len(prices) < period:
        return []
    result = []
    for i in range(period - 1, len(prices)):
        window = prices[i - period + 1 : i + 1]
        result.append(sum(window) / period)
    return result


def ema(prices: List[float], period: int) -> List[float]:
    """
    Exponential Moving Average.
    EMA_t = price_t * k + EMA_(t-1) * (1 - k),  k = 2 / (period + 1)
    Seed: first EMA value = SMA of first `period` prices.
    """
    if len(prices) < period:
        return []
    k = 2.0 / (period + 1)
    seed = sum(prices[:period]) / period
    result = [seed]
    for price in prices[period:]:
        result.append(price * k + result[-1] * (1 - k))
    return result


def rsi(prices: List[float], period: int = 14) -> RSIResult:
    """
    Relative Strength Index.
    RS = avg_gain / avg_loss  (Wilder smoothing after initial window)
    RSI = 100 - 100 / (1 + RS)
    """
    if len(prices) < period + 1:
        return RSIResult(period=period, values=[], latest=float("nan"))
    deltas = [prices[i] - prices[i - 1] for i in range(1, len(prices))]
    gains = [max(d, 0.0) for d in deltas]
    losses = [abs(min(d, 0.0)) for d in deltas]

    avg_gain = sum(gains[:period]) / period
    avg_loss = sum(losses[:period]) / period

    rsi_values = []
    for i in range(period, len(deltas)):
        if avg_loss == 0:
            rsi_values.append(100.0)
        else:
            rs = avg_gain / avg_loss
            rsi_values.append(100.0 - 100.0 / (1.0 + rs))
        avg_gain = (avg_gain * (period - 1) + gains[i]) / period
        avg_loss = (avg_loss * (period - 1) + losses[i]) / period

    # first value from initial window
    if avg_loss == 0:
        first = 100.0
    else:
        rs0 = sum(gains[:period]) / period / (sum(losses[:period]) / period)
        first = 100.0 - 100.0 / (1.0 + rs0)
    all_values = [first] + rsi_values
    return RSIResult(period=period, values=all_values, latest=all_values[-1])


def macd(
    prices: List[float],
    fast: int = 12,
    slow: int = 26,
    signal_period: int = 9,
) -> MACDResult:
    """
    MACD = EMA_fast - EMA_slow
    Signal = EMA_signal of MACD
    Histogram = MACD - Signal
    """
    ema_fast = ema(prices, fast)
    ema_slow = ema(prices, slow)
    # align: ema_slow is shorter
    offset = len(ema_fast) - len(ema_slow)
    macd_line = [f - s for f, s in zip(ema_fast[offset:], ema_slow)]
    signal = ema(macd_line, signal_period)
    sig_offset = len(macd_line) - len(signal)
    histogram = [m - s for m, s in zip(macd_line[sig_offset:], signal)]
    return MACDResult(
        macd_line=macd_line,
        signal_line=signal,
        histogram=histogram,
        latest_macd=macd_line[-1] if macd_line else float("nan"),
        latest_signal=signal[-1] if signal else float("nan"),
        latest_histogram=histogram[-1] if histogram else float("nan"),
    )


def bollinger_bands(
    prices: List[float], period: int = 20, num_std: float = 2.0
) -> BollingerBand:
    """
    Middle = SMA_period
    Upper  = Middle + num_std * σ
    Lower  = Middle - num_std * σ
    """
    middles = sma(prices, period)
    uppers, lowers = [], []
    for i, mid in enumerate(middles):
        window = prices[i : i + period]
        sigma = statistics.pstdev(window)
        uppers.append(mid + num_std * sigma)
        lowers.append(mid - num_std * sigma)
    bw = ((uppers[-1] - lowers[-1]) / middles[-1]) if middles else float("nan")
    return BollingerBand(
        period=period,
        std_dev=num_std,
        upper=uppers,
        middle=middles,
        lower=lowers,
        latest_upper=uppers[-1] if uppers else float("nan"),
        latest_middle=middles[-1] if middles else float("nan"),
        latest_lower=lowers[-1] if lowers else float("nan"),
        bandwidth=bw,
    )


def stochastic(
    bars: List[PriceBar], k_period: int = 14, d_period: int = 3
) -> Tuple[List[float], List[float]]:
    """
    %K = (C - L14) / (H14 - L14) * 100
    %D = SMA3(%K)
    """
    k_values = []
    for i in range(k_period - 1, len(bars)):
        window = bars[i - k_period + 1 : i + 1]
        low14  = min(b.low  for b in window)
        high14 = max(b.high for b in window)
        close  = bars[i].close
        denom  = high14 - low14
        k_values.append(100.0 * (close - low14) / denom if denom != 0 else 50.0)
    d_values = sma(k_values, d_period)
    return k_values, d_values


def atr(bars: List[PriceBar], period: int = 14) -> List[float]:
    """
    True Range = max(H-L, |H-Prev_C|, |L-Prev_C|)
    ATR = Wilder smoothed average of TR over `period`
    """
    trs = []
    for i in range(1, len(bars)):
        h, l, pc = bars[i].high, bars[i].low, bars[i - 1].close
        trs.append(max(h - l, abs(h - pc), abs(l - pc)))
    if len(trs) < period:
        return []
    atr_val = sum(trs[:period]) / period
    result = [atr_val]
    for tr in trs[period:]:
        atr_val = (atr_val * (period - 1) + tr) / period
        result.append(atr_val)
    return result


def obv(bars: List[PriceBar]) -> List[float]:
    """
    On-Balance Volume:
    OBV_t = OBV_(t-1) + volume  if close > prev_close
          = OBV_(t-1) - volume  if close < prev_close
          = OBV_(t-1)           otherwise
    """
    result = [0.0]
    for i in range(1, len(bars)):
        diff = bars[i].close - bars[i - 1].close
        if diff > 0:
            result.append(result[-1] + bars[i].volume)
        elif diff < 0:
            result.append(result[-1] - bars[i].volume)
        else:
            result.append(result[-1])
    return result


def vwap(bars: List[PriceBar]) -> float:
    """VWAP = Σ(typical_price * volume) / Σ(volume)"""
    num = sum(((b.high + b.low + b.close) / 3.0) * b.volume for b in bars)
    den = sum(b.volume for b in bars)
    return num / den if den else float("nan")


def pivot_points(bar: PriceBar) -> SupportResistance:
    """
    P  = (H + L + C) / 3
    R1 = 2P - L,  R2 = P + (H - L),  R3 = H + 2*(P - L)
    S1 = 2P - H,  S2 = P - (H - L),  S3 = L - 2*(H - P)
    """
    p  = (bar.high + bar.low + bar.close) / 3.0
    r1 = 2 * p - bar.low
    r2 = p + (bar.high - bar.low)
    r3 = bar.high + 2 * (p - bar.low)
    s1 = 2 * p - bar.high
    s2 = p - (bar.high - bar.low)
    s3 = bar.low - 2 * (bar.high - p)
    return SupportResistance(pivot=p, r1=r1, r2=r2, r3=r3, s1=s1, s2=s2, s3=s3)


# ── Risk / Performance Metrics ───────────────────────────────────────────────

def daily_returns(prices: List[float]) -> List[float]:
    return [(prices[i] - prices[i - 1]) / prices[i - 1] for i in range(1, len(prices))]


def sharpe_ratio(returns: List[float], risk_free: float = 0.0) -> float:
    """
    Sharpe = (mean_return - risk_free) / std_return * sqrt(252)
    Annualised assuming daily returns.
    """
    if len(returns) < 2:
        return float("nan")
    excess = [r - risk_free / 252 for r in returns]
    mean_e = statistics.mean(excess)
    std_e  = statistics.pstdev(excess)
    return (mean_e / std_e * math.sqrt(252)) if std_e else float("nan")


def max_drawdown(prices: List[float]) -> float:
    """Maximum peak-to-trough decline as a fraction."""
    peak = prices[0]
    max_dd = 0.0
    for p in prices:
        if p > peak:
            peak = p
        dd = (peak - p) / peak if peak else 0.0
        max_dd = max(max_dd, dd)
    return max_dd


def kelly_criterion(win_rate: float, avg_win: float, avg_loss: float) -> float:
    """
    Kelly fraction = W/A - (1-W)/B
    W = win_rate, A = avg_loss (as positive), B = avg_win
    Capped at 0..0.25 for practical use.
    """
    if avg_loss == 0:
        return 0.0
    k = (win_rate / avg_loss) - ((1 - win_rate) / avg_win)
    return max(0.0, min(k, 0.25))


# ── Signal Generation ────────────────────────────────────────────────────────

def generate_signals(bars: List[PriceBar]) -> List[TradingSignal]:
    if len(bars) < 35:
        return []
    closes  = [b.close for b in bars]
    signals: List[TradingSignal] = []
    last    = bars[-1]

    # RSI signal
    rsi_result = rsi(closes)
    if rsi_result.values:
        r = rsi_result.latest
        if r < 30:
            signals.append(TradingSignal(
                symbol=last.symbol, date=last.date, signal="BUY",
                source="RSI", strength=round((30 - r) / 30, 2),
                price=last.close, note=f"RSI={r:.1f} oversold"
            ))
        elif r > 70:
            signals.append(TradingSignal(
                symbol=last.symbol, date=last.date, signal="SELL",
                source="RSI", strength=round((r - 70) / 30, 2),
                price=last.close, note=f"RSI={r:.1f} overbought"
            ))

    # MACD crossover
    m = macd(closes)
    if len(m.histogram) >= 2:
        prev_h = m.histogram[-2]
        curr_h = m.histogram[-1]
        if prev_h < 0 < curr_h:
            signals.append(TradingSignal(
                symbol=last.symbol, date=last.date, signal="BUY",
                source="MACD", strength=0.7,
                price=last.close, note="MACD bullish crossover"
            ))
        elif prev_h > 0 > curr_h:
            signals.append(TradingSignal(
                symbol=last.symbol, date=last.date, signal="SELL",
                source="MACD", strength=0.7,
                price=last.close, note="MACD bearish crossover"
            ))

    # Bollinger Band breakout / squeeze
    bb = bollinger_bands(closes)
    if bb.latest_upper and bb.latest_lower:
        if last.close > bb.latest_upper:
            signals.append(TradingSignal(
                symbol=last.symbol, date=last.date, signal="SELL",
                source="BB", strength=0.6,
                price=last.close, note="Price above upper Bollinger Band"
            ))
        elif last.close < bb.latest_lower:
            signals.append(TradingSignal(
                symbol=last.symbol, date=last.date, signal="BUY",
                source="BB", strength=0.6,
                price=last.close, note="Price below lower Bollinger Band"
            ))

    # Golden / Death cross (SMA50 vs SMA200)
    sma50  = sma(closes, 50)
    sma200 = sma(closes, 200)
    if len(sma50) >= 2 and len(sma200) >= 2:
        if sma50[-2] <= sma200[-2] and sma50[-1] > sma200[-1]:
            signals.append(TradingSignal(
                symbol=last.symbol, date=last.date, signal="BUY",
                source="CROSS", strength=0.9,
                price=last.close, note="Golden Cross: SMA50 crossed above SMA200"
            ))
        elif sma50[-2] >= sma200[-2] and sma50[-1] < sma200[-1]:
            signals.append(TradingSignal(
                symbol=last.symbol, date=last.date, signal="SELL",
                source="CROSS", strength=0.9,
                price=last.close, note="Death Cross: SMA50 crossed below SMA200"
            ))

    if not signals:
        signals.append(TradingSignal(
            symbol=last.symbol, date=last.date, signal="NEUTRAL",
            source="ALL", strength=0.0,
            price=last.close, note="No decisive signal"
        ))
    return signals


# ── Backtester ───────────────────────────────────────────────────────────────

def backtest(bars: List[PriceBar]) -> dict:
    """
    Simple signal-based backtest: enter on BUY signal, exit on SELL.
    Returns win_rate, avg_win, avg_loss, total_return, sharpe, max_dd, kelly.
    """
    trades = []
    position: Optional[float] = None

    for i in range(35, len(bars)):
        sigs = generate_signals(bars[: i + 1])
        top = max(sigs, key=lambda s: s.strength) if sigs else None
        if top is None:
            continue
        if top.signal == "BUY" and position is None:
            position = bars[i].close
        elif top.signal == "SELL" and position is not None:
            ret = (bars[i].close - position) / position
            trades.append(ret)
            position = None

    if not trades:
        return {"trades": 0}

    wins    = [t for t in trades if t > 0]
    losses  = [t for t in trades if t <= 0]
    wr      = len(wins) / len(trades)
    avg_w   = statistics.mean(wins)   if wins   else 0.0
    avg_l   = abs(statistics.mean(losses)) if losses else 0.0
    total_r = math.prod(1 + t for t in trades) - 1
    ret_series  = daily_returns([b.close for b in bars])
    sp = sharpe_ratio(ret_series)
    md = max_drawdown([b.close for b in bars])
    kc = kelly_criterion(wr, avg_w, avg_l)

    return {
        "trades":       len(trades),
        "win_rate":     round(wr, 3),
        "avg_win":      round(avg_w, 4),
        "avg_loss":     round(avg_l, 4),
        "total_return": round(total_r, 4),
        "sharpe":       round(sp, 3),
        "max_drawdown": round(md, 4),
        "kelly":        round(kc, 3),
    }


# ── ASCII Chart ──────────────────────────────────────────────────────────────

def ascii_chart(bars: List[PriceBar], width: int = 60, height: int = 15) -> None:
    if not bars:
        return
    closes = [b.close for b in bars[-width:]]
    lo, hi = min(closes), max(closes)
    rng = hi - lo or 1.0
    print(f"\n{CYAN}{'─'*width}{RESET}")
    for row in range(height, -1, -1):
        level = lo + rng * row / height
        line  = ""
        for price in closes:
            norm = (price - lo) / rng * height
            char = "█" if abs(norm - row) < 0.6 else " "
            color = GREEN if price >= closes[0] else RED
            line += color + char + RESET
        tag = f" {level:8.2f}" if row % 3 == 0 else ""
        print(f"|{line}|{tag}")
    print(f"{CYAN}{'─'*width}{RESET}  {bars[-width].date} → {bars[-1].date}\n")


# ── CLI Commands ─────────────────────────────────────────────────────────────

def cmd_add_price(args: argparse.Namespace) -> None:
    conn = get_conn()
    bar = PriceBar(
        symbol=args.symbol.upper(),
        date=args.date or str(date.today()),
        open=args.open,
        high=args.high,
        low=args.low,
        close=args.close,
        volume=args.volume,
    )
    insert_bar(conn, bar)
    print(f"{GREEN}✓ Added {bar.symbol} {bar.date} close={bar.close}{RESET}")


def cmd_analyze(args: argparse.Namespace) -> None:
    conn  = get_conn()
    bars  = load_bars(conn, args.symbol.upper())
    if len(bars) < 35:
        print(f"{RED}Need at least 35 bars (got {len(bars)}){RESET}")
        return
    closes = [b.close for b in bars]

    ascii_chart(bars)

    rsi_r = rsi(closes)
    m     = macd(closes)
    bb    = bollinger_bands(closes)
    atr_v = atr(bars)
    vw    = vwap(bars)
    obv_v = obv(bars)
    pivs  = pivot_points(bars[-1])

    print(f"{BOLD}{CYAN}══ {args.symbol.upper()} Technical Analysis ══{RESET}")
    print(f"  Close:   {closes[-1]:.2f}")
    print(f"  SMA20:   {sma(closes, 20)[-1]:.2f}   SMA50: {sma(closes, 50)[-1] if len(closes)>=50 else 'n/a'}")
    print(f"  EMA12:   {ema(closes, 12)[-1]:.2f}   EMA26: {ema(closes, 26)[-1]:.2f}")
    print(f"  RSI14:   {rsi_r.latest:.1f}  {'(oversold)' if rsi_r.latest<30 else '(overbought)' if rsi_r.latest>70 else ''}")
    print(f"  MACD:    {m.latest_macd:.4f}  Signal: {m.latest_signal:.4f}  Hist: {m.latest_histogram:.4f}")
    print(f"  BB:      U={bb.latest_upper:.2f}  M={bb.latest_middle:.2f}  L={bb.latest_lower:.2f}  BW={bb.bandwidth:.3f}")
    print(f"  ATR14:   {atr_v[-1]:.2f}")
    print(f"  VWAP:    {vw:.2f}")
    print(f"  OBV:     {obv_v[-1]:,.0f}")
    print(f"\n{CYAN}  Pivot Points:{RESET}")
    print(f"    P={pivs.pivot:.2f}  R1={pivs.r1:.2f}  R2={pivs.r2:.2f}  R3={pivs.r3:.2f}")
    print(f"              S1={pivs.s1:.2f}  S2={pivs.s2:.2f}  S3={pivs.s3:.2f}")


def cmd_signals(args: argparse.Namespace) -> None:
    conn   = get_conn()
    bars   = load_bars(conn, args.symbol.upper())
    sigs   = generate_signals(bars)
    print(f"{BOLD}{CYAN}══ Signals for {args.symbol.upper()} ══{RESET}")
    for s in sigs:
        color = GREEN if s.signal == "BUY" else RED if s.signal == "SELL" else YELLOW
        print(f"  {color}{s.signal:7}{RESET}  [{s.source:5}] str={s.strength:.2f}  {s.note}")
        save_signal(conn, s)


def cmd_backtest(args: argparse.Namespace) -> None:
    conn   = get_conn()
    bars   = load_bars(conn, args.symbol.upper())
    result = backtest(bars)
    print(f"{BOLD}{CYAN}══ Backtest: {args.symbol.upper()} ══{RESET}")
    for k, v in result.items():
        print(f"  {k:15}: {v}")


def cmd_report(args: argparse.Namespace) -> None:
    conn   = get_conn()
    bars   = load_bars(conn, args.symbol.upper())
    if not bars:
        print(f"{RED}No data for {args.symbol}{RESET}")
        return
    closes = [b.close for b in bars]
    rets   = daily_returns(closes)
    sp     = sharpe_ratio(rets)
    md     = max_drawdown(closes)
    print(f"{BOLD}{CYAN}══ Report: {args.symbol.upper()} ══{RESET}")
    print(f"  Bars:        {len(bars)}")
    print(f"  Date range:  {bars[0].date} → {bars[-1].date}")
    print(f"  Price range: {min(closes):.2f} – {max(closes):.2f}")
    print(f"  Sharpe:      {sp:.3f}")
    print(f"  Max Drawdown:{md*100:.2f}%")
    total_r = (closes[-1] - closes[0]) / closes[0] * 100
    print(f"  Total Return:{total_r:.2f}%")


# ── Entry Point ───────────────────────────────────────────────────────────────

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="stock",
        description="BlackRoad Quantitative Technical Analysis"
    )
    sub = p.add_subparsers(dest="command")

    # add-price
    ap = sub.add_parser("add-price", help="Insert a price bar")
    ap.add_argument("symbol")
    ap.add_argument("--date",   default=None)
    ap.add_argument("--open",   type=float, required=True)
    ap.add_argument("--high",   type=float, required=True)
    ap.add_argument("--low",    type=float, required=True)
    ap.add_argument("--close",  type=float, required=True)
    ap.add_argument("--volume", type=float, default=0.0)

    for cmd, fn in [("analyze",""), ("signals",""), ("backtest",""), ("report","")]:
        sp2 = sub.add_parser(cmd, help=f"Run {cmd}")
        sp2.add_argument("symbol")

    return p


def main():
    parser = build_parser()
    args   = parser.parse_args()
    dispatch = {
        "add-price": cmd_add_price,
        "analyze":   cmd_analyze,
        "signals":   cmd_signals,
        "backtest":  cmd_backtest,
        "report":    cmd_report,
    }
    fn = dispatch.get(args.command)
    if fn:
        fn(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()

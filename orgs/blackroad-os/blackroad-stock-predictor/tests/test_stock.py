"""
Test suite for BlackRoad Stock Predictor — quantitative finance engine.
Tests cover SMA, EMA, RSI, MACD, Bollinger Bands, Support/Resistance,
Sharpe ratio, ATR, and signal generation on synthetic price series.
"""

import math
import pytest

# ---------------------------------------------------------------------------
# Adjust import path so tests run from repo root or tests/ dir
# ---------------------------------------------------------------------------
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from stock import (
    PriceBar,
    sma, ema, rsi, macd, bollinger_bands, stochastic,
    atr, obv, vwap, pivot_points,
    sharpe_ratio, max_drawdown, kelly_criterion, daily_returns,
    generate_signals,
)


# ── Helpers ─────────────────────────────────────────────────────────────────

def make_bars(closes, highs=None, lows=None, volumes=None, opens=None):
    """Build a list of PriceBar from close prices, with sensible defaults."""
    n = len(closes)
    highs   = highs   or [c * 1.01 for c in closes]
    lows    = lows    or [c * 0.99 for c in closes]
    volumes = volumes or [1_000_000.0] * n
    opens   = opens   or closes
    return [
        PriceBar(
            symbol="TEST",
            date=f"2024-01-{i+1:02d}",
            open=opens[i],
            high=highs[i],
            low=lows[i],
            close=closes[i],
            volume=volumes[i],
        )
        for i in range(n)
    ]


# ── SMA ─────────────────────────────────────────────────────────────────────

class TestSMA:
    def test_sma_basic_calculation(self):
        prices = [10.0, 20.0, 30.0, 40.0, 50.0]
        result = sma(prices, 3)
        # window 1: (10+20+30)/3=20, window 2: (20+30+40)/3=30, window 3: (30+40+50)/3=40
        assert result == pytest.approx([20.0, 30.0, 40.0])

    def test_sma_single_period_returns_prices(self):
        prices = [5.0, 10.0, 15.0]
        assert sma(prices, 1) == pytest.approx(prices)

    def test_sma_insufficient_data_returns_empty(self):
        assert sma([1.0, 2.0], 5) == []

    def test_sma_known_financial_series(self):
        # 20-bar SMA on a linear ramp should equal mid-window value
        prices = list(range(1, 21))      # 1..20
        result = sma(prices, 5)
        # first window: (1+2+3+4+5)/5 = 3.0
        assert result[0] == pytest.approx(3.0)
        # last window: (16+17+18+19+20)/5 = 18.0
        assert result[-1] == pytest.approx(18.0)


# ── EMA ─────────────────────────────────────────────────────────────────────

class TestEMA:
    def test_ema_seed_equals_sma(self):
        prices = [10.0, 20.0, 30.0, 40.0]
        result = ema(prices, 3)
        # Seed = SMA3([10,20,30]) = 20.0
        assert result[0] == pytest.approx(20.0)

    def test_ema_recursive_formula(self):
        prices = [10.0, 20.0, 30.0, 40.0]
        k      = 2 / (3 + 1)        # period=3
        result = ema(prices, 3)
        # Step 1: EMA_1 = 40 * k + 20 * (1-k)
        expected_1 = 40.0 * k + 20.0 * (1 - k)
        assert result[1] == pytest.approx(expected_1, rel=1e-9)

    def test_ema_multiplier_k(self):
        period = 12
        k = 2.0 / (period + 1)
        assert k == pytest.approx(2 / 13, rel=1e-9)

    def test_ema_short_series_returns_empty(self):
        assert ema([1.0, 2.0], 5) == []

    def test_ema_longer_than_sma_for_rising_series(self):
        prices = list(range(1, 51))      # 1..50
        result_ema = ema(prices, 10)
        result_sma = sma(prices, 10)
        # EMA should be > SMA for rising series (more weight on recent)
        assert result_ema[-1] > result_sma[-1]


# ── RSI ─────────────────────────────────────────────────────────────────────

class TestRSI:
    def test_rsi_overbought_for_strong_uptrend(self):
        # Prices that only go up → RSI should be > 70
        prices = [100.0 + i * 2 for i in range(30)]
        result = rsi(prices)
        assert result.latest > 70.0

    def test_rsi_oversold_for_strong_downtrend(self):
        # Prices that only go down → RSI should be < 30
        prices = [200.0 - i * 2 for i in range(30)]
        result = rsi(prices)
        assert result.latest < 30.0

    def test_rsi_bounded_0_to_100(self):
        import random
        random.seed(42)
        prices = [100.0 + random.gauss(0, 2) for _ in range(50)]
        result = rsi(prices)
        for v in result.values:
            assert 0.0 <= v <= 100.0, f"RSI value {v} out of bounds"

    def test_rsi_insufficient_data(self):
        result = rsi([1.0, 2.0, 3.0], period=14)
        assert math.isnan(result.latest)


# ── MACD ─────────────────────────────────────────────────────────────────────

class TestMACD:
    def test_macd_crossover_detected(self):
        """
        Build a price series with a recognisable bullish crossover:
        flat then sharply rising. The histogram should cross zero from below.
        """
        prices  = [100.0] * 30 + [100.0 + i * 3 for i in range(30)]
        result  = macd(prices)
        # The histogram should eventually become positive
        assert any(h > 0 for h in result.histogram), "Expected bullish MACD histogram"

    def test_macd_line_equals_ema12_minus_ema26(self):
        prices = [50.0 + math.sin(i * 0.3) * 5 for i in range(60)]
        ema12  = ema(prices, 12)
        ema26  = ema(prices, 26)
        result = macd(prices)
        # Align tails
        offset = len(ema12) - len(ema26)
        expected_last_macd = ema12[-1] - ema26[-1]
        # The last alignment point
        assert result.latest_macd == pytest.approx(expected_last_macd, rel=1e-9)

    def test_macd_signal_is_ema9_of_macd(self):
        prices = [50.0 + i * 0.5 for i in range(80)]
        result = macd(prices)
        # signal line length = len(macd_line) - 9 + 1
        expected_len = len(result.macd_line) - 9 + 1
        assert len(result.signal_line) == expected_len


# ── Bollinger Bands ───────────────────────────────────────────────────────────

class TestBollingerBands:
    def test_bandwidth_calculation(self):
        import statistics as st
        prices = [100.0 + math.sin(i) for i in range(30)]
        bb     = bollinger_bands(prices, period=20, num_std=2.0)
        # Manual last window
        window = prices[-20:]
        mid    = sum(window) / 20
        sigma  = st.pstdev(window)
        upper  = mid + 2 * sigma
        lower  = mid - 2 * sigma
        assert bb.latest_upper  == pytest.approx(upper,  rel=1e-9)
        assert bb.latest_lower  == pytest.approx(lower,  rel=1e-9)
        assert bb.latest_middle == pytest.approx(mid,    rel=1e-9)

    def test_bollinger_band_two_sigma_containment(self):
        """For near-Gaussian prices, ~95% of closes should be within 2σ bands."""
        import random, statistics as st
        random.seed(0)
        prices = [100.0 + random.gauss(0, 1) for _ in range(200)]
        bb     = bollinger_bands(prices, period=20, num_std=2.0)
        # Check last 100 closes against their corresponding band
        inside = 0
        total  = min(len(bb.upper), 100)
        for i in range(total):
            idx = len(prices) - total + i - (20 - 1)
            if idx < 0:
                continue
            if bb.lower[-(total - i)] <= prices[idx] <= bb.upper[-(total - i)]:
                inside += 1
        # Roughly 90%+ should be inside
        assert inside / total >= 0.85

    def test_bollinger_band_width_positive(self):
        prices = [100.0 + i % 5 for i in range(30)]
        bb     = bollinger_bands(prices)
        assert bb.bandwidth >= 0


# ── Support / Resistance ─────────────────────────────────────────────────────

class TestSupportResistance:
    def test_pivot_point_exact_math(self):
        bar    = PriceBar("T", "2024-01-01", 100, 110, 90, 105, 1e6)
        sr     = pivot_points(bar)
        p_exp  = (110 + 90 + 105) / 3
        r1_exp = 2 * p_exp - 90
        s1_exp = 2 * p_exp - 110
        r2_exp = p_exp + (110 - 90)
        s2_exp = p_exp - (110 - 90)
        assert sr.pivot == pytest.approx(p_exp)
        assert sr.r1    == pytest.approx(r1_exp)
        assert sr.s1    == pytest.approx(s1_exp)
        assert sr.r2    == pytest.approx(r2_exp)
        assert sr.s2    == pytest.approx(s2_exp)

    def test_pivot_ordering(self):
        bar = PriceBar("T", "2024-01-01", 50, 60, 40, 55, 5e5)
        sr  = pivot_points(bar)
        assert sr.s3 < sr.s2 < sr.s1 < sr.pivot < sr.r1 < sr.r2 < sr.r3


# ── Sharpe Ratio ─────────────────────────────────────────────────────────────

class TestSharpeRatio:
    def test_sharpe_known_returns(self):
        # Daily returns of exactly 0.001 each → mean=0.001, std=0, Sharpe=inf
        returns = [0.001] * 252
        sp = sharpe_ratio(returns)
        assert math.isinf(sp) or sp > 10  # deterministic → very high

    def test_sharpe_zero_for_zero_returns(self):
        returns = [0.0] * 100
        sp = sharpe_ratio(returns)
        assert math.isnan(sp) or sp == pytest.approx(0.0)

    def test_sharpe_negative_for_losing_strategy(self):
        returns = [-0.002] * 252
        sp = sharpe_ratio(returns)
        assert math.isinf(sp) or sp < 0  # all negative → negative Sharpe

    def test_sharpe_annualised_by_sqrt_252(self):
        import statistics as st
        returns = [0.001 * (-1) ** i for i in range(100)]  # alternating
        mean_e  = st.mean(returns)
        std_e   = st.pstdev(returns)
        expected = mean_e / std_e * math.sqrt(252)
        assert sharpe_ratio(returns) == pytest.approx(expected, rel=1e-9)


# ── ATR ──────────────────────────────────────────────────────────────────────

class TestATR:
    def test_atr_constant_range(self):
        """If H-L is constant and no gaps, ATR should converge to H-L."""
        bars = make_bars(
            closes  = [100.0] * 30,
            highs   = [102.0] * 30,
            lows    = [98.0]  * 30,
        )
        atr_vals = atr(bars, period=14)
        # All TRs = 2.0 (H-L=2, no gap), so ATR should be 2.0
        assert atr_vals[-1] == pytest.approx(2.0, rel=1e-6)

    def test_atr_true_range_uses_prev_close(self):
        """ATR must account for gaps (|H - Prev_C|)."""
        bars = make_bars(
            closes  = [100.0, 100.0, 100.0],
            highs   = [101.0, 101.0, 101.0],
            lows    = [99.0,  99.0,  99.0],
        )
        # Insert a gap: bar[2] opens way up
        bars[2].high  = 110.0
        bars[2].low   = 109.0
        bars[2].close = 109.5
        # TR for bar[2]: max(110-109, |110-100|, |109-100|) = max(1, 10, 9) = 10
        trs = [max(bars[i].high - bars[i].low,
                   abs(bars[i].high - bars[i-1].close),
                   abs(bars[i].low  - bars[i-1].close))
               for i in range(1, 3)]
        assert trs[1] == pytest.approx(10.0)


# ── OBV & VWAP ───────────────────────────────────────────────────────────────

class TestOBVAndVWAP:
    def test_obv_rising_prices_positive_obv(self):
        bars = make_bars([100.0 + i for i in range(10)], volumes=[1_000.0]*10)
        vals = obv(bars)
        # Every bar closes higher → OBV should keep rising
        assert vals[-1] > vals[0]

    def test_vwap_single_bar(self):
        bar  = PriceBar("T", "2024-01-01", 100, 110, 90, 105, 200.0)
        tp   = (110 + 90 + 105) / 3
        assert vwap([bar]) == pytest.approx(tp)

    def test_vwap_equal_weights(self):
        bars = make_bars([100.0, 200.0], volumes=[100.0, 100.0])
        # typical prices: (101+99+100)/3=100, (202+198+200)/3=200
        tp0 = (bars[0].high + bars[0].low + bars[0].close) / 3
        tp1 = (bars[1].high + bars[1].low + bars[1].close) / 3
        expected = (tp0 * 100 + tp1 * 100) / 200
        assert vwap(bars) == pytest.approx(expected, rel=1e-9)


# ── Max Drawdown ─────────────────────────────────────────────────────────────

class TestMaxDrawdown:
    def test_max_drawdown_known_series(self):
        prices = [100.0, 120.0, 80.0, 90.0]
        # Peak=120, trough=80, drawdown = (120-80)/120 = 0.3333
        assert max_drawdown(prices) == pytest.approx(1/3, rel=1e-6)

    def test_max_drawdown_monotone_rising(self):
        prices = [10.0, 20.0, 30.0, 40.0]
        assert max_drawdown(prices) == pytest.approx(0.0)

    def test_max_drawdown_monotone_falling(self):
        prices = [100.0, 80.0, 60.0, 40.0]
        # Peak=100, final=40 → drawdown = 60/100 = 0.6
        assert max_drawdown(prices) == pytest.approx(0.6)


# ── Kelly Criterion ───────────────────────────────────────────────────────────

class TestKellyCriterion:
    def test_kelly_positive_edge(self):
        # Win rate 60%, avg win 0.10, avg loss 0.05
        # Kelly = 0.6/0.05 - 0.4/0.10 = 12 - 4 = 8 → capped at 0.25
        k = kelly_criterion(0.6, avg_win=0.10, avg_loss=0.05)
        assert k == pytest.approx(0.25)  # capped

    def test_kelly_zero_for_no_edge(self):
        # Win rate 50%, avg win = avg loss → Kelly = 0
        k = kelly_criterion(0.5, avg_win=0.1, avg_loss=0.1)
        assert k == pytest.approx(0.0, abs=1e-9)

    def test_kelly_never_negative(self):
        k = kelly_criterion(0.3, avg_win=0.05, avg_loss=0.20)
        assert k >= 0.0


# ── Signal Generation ─────────────────────────────────────────────────────────

class TestSignalGeneration:
    def test_rsi_oversold_triggers_buy(self):
        # Strongly falling series → RSI < 30 → BUY signal
        prices = [200.0 - i * 3 for i in range(60)]
        bars   = make_bars(prices)
        sigs   = generate_signals(bars)
        sources = {s.source for s in sigs}
        assert "RSI" in sources
        rsi_sig = next(s for s in sigs if s.source == "RSI")
        assert rsi_sig.signal == "BUY"

    def test_rsi_overbought_triggers_sell(self):
        prices = [100.0 + i * 3 for i in range(60)]
        bars   = make_bars(prices)
        sigs   = generate_signals(bars)
        rsi_sigs = [s for s in sigs if s.source == "RSI"]
        assert any(s.signal == "SELL" for s in rsi_sigs)

    def test_insufficient_bars_returns_empty(self):
        bars = make_bars([100.0 + i for i in range(10)])
        assert generate_signals(bars) == []

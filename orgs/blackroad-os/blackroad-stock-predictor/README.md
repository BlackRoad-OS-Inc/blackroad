# BlackRoad Stock Predictor 📈

A **quantitative technical analysis engine** implementing real financial algorithms for price-action research, signal generation, backtesting, and risk management — entirely in Python with zero external dependencies beyond the standard library.

---

## Mathematical Background

### Moving Averages

**Simple Moving Average (SMA)**

$$\text{SMA}_n = \frac{1}{n}\sum_{i=0}^{n-1} P_{t-i}$$

Treats all periods equally. Used as the basis for Bollinger Bands and the Golden/Death Cross.

**Exponential Moving Average (EMA)**

$$k = \frac{2}{n+1}, \qquad \text{EMA}_t = P_t \cdot k + \text{EMA}_{t-1} \cdot (1-k)$$

Seeded with SMA of the first *n* prices. Gives more weight to recent observations. Used in MACD.

---

### RSI — Relative Strength Index (Wilder, 1978)

$$\text{RS} = \frac{\overline{\text{Gain}_{14}}}{\overline{\text{Loss}_{14}}}, \qquad \text{RSI} = 100 - \frac{100}{1+\text{RS}}$$

Wilder smoothing: after the initial window, averages are updated as:

$$\overline{G}_t = \frac{\overline{G}_{t-1}(n-1)+G_t}{n}$$

- RSI < 30 → **oversold** (potential BUY)
- RSI > 70 → **overbought** (potential SELL)

---

### MACD — Moving Average Convergence/Divergence (Appel, 1979)

$$\text{MACD} = \text{EMA}_{12} - \text{EMA}_{26}$$

$$\text{Signal} = \text{EMA}_9(\text{MACD})$$

$$\text{Histogram} = \text{MACD} - \text{Signal}$$

Histogram crossing zero from below → **bullish crossover (BUY)**.  
Histogram crossing zero from above → **bearish crossover (SELL)**.

---

### Bollinger Bands (Bollinger, 1983)

$$\text{Middle} = \text{SMA}_{20}, \quad \sigma = \sqrt{\frac{1}{n}\sum_{i=1}^{n}(P_i - \overline{P})^2}$$

$$\text{Upper} = \text{Middle} + 2\sigma, \qquad \text{Lower} = \text{Middle} - 2\sigma$$

$$\text{Bandwidth} = \frac{\text{Upper} - \text{Lower}}{\text{Middle}}$$

Price touching/crossing the upper band signals potential reversal (SELL); lower band → potential reversal (BUY). Narrow bandwidth = low volatility "squeeze" before a breakout.

---

### Stochastic Oscillator (Lane, 1950s)

$$\%K = \frac{C - L_{14}}{H_{14} - L_{14}} \times 100, \qquad \%D = \text{SMA}_3(\%K)$$

- %K > 80 → overbought; %K < 20 → oversold.

---

### ATR — Average True Range (Wilder, 1978)

$$\text{TR}_t = \max(H_t - L_t,\; |H_t - C_{t-1}|,\; |L_t - C_{t-1}|)$$

$$\text{ATR}_t = \frac{\text{ATR}_{t-1}(n-1) + \text{TR}_t}{n}$$

ATR measures volatility irrespective of direction. Essential for position sizing.

---

### OBV — On-Balance Volume (Granville, 1963)

$$\text{OBV}_t = \begin{cases} \text{OBV}_{t-1} + V_t & C_t > C_{t-1} \\ \text{OBV}_{t-1} - V_t & C_t < C_{t-1} \\ \text{OBV}_{t-1} & C_t = C_{t-1} \end{cases}$$

Rising OBV on rising price → confirms trend. Divergence signals weakness.

---

### VWAP — Volume-Weighted Average Price

$$\text{VWAP} = \frac{\sum_t P^{\text{typical}}_t \cdot V_t}{\sum_t V_t}, \qquad P^{\text{typical}} = \frac{H+L+C}{3}$$

Institutional benchmark; price > VWAP is generally bullish intraday.

---

### Pivot Points (Floor Trader Method)

$$P = \frac{H+L+C}{3}$$

| Level | Formula |
|-------|---------|
| R1 | $2P - L$ |
| R2 | $P + (H - L)$ |
| R3 | $H + 2(P - L)$ |
| S1 | $2P - H$ |
| S2 | $P - (H - L)$ |
| S3 | $L - 2(H - P)$ |

---

### Risk Metrics

**Sharpe Ratio (Sharpe, 1966)**

$$\text{Sharpe} = \frac{E[r] - r_f}{\sigma_r} \times \sqrt{252}$$

Annualised from daily returns. Higher is better (> 1 acceptable, > 2 excellent).

**Maximum Drawdown**

$$\text{MaxDD} = \max_t \frac{\text{Peak}_t - P_t}{\text{Peak}_t}$$

**Kelly Criterion (Kelly, 1956)**

$$f^* = \frac{W}{A} - \frac{1-W}{B}$$

Where *W* = win rate, *A* = avg loss, *B* = avg win. Capped at 25% for practical use.

---

## Installation

```bash
# No external dependencies required — uses Python standard library only
python -m venv venv && source venv/bin/activate
pip install pytest pytest-cov   # only for running tests
```

---

## Usage

### Add price data

```bash
python src/stock.py add-price AAPL \
  --date 2024-01-15 \
  --open 185.50 --high 187.20 --low 184.80 --close 186.40 --volume 52000000
```

### Run technical analysis

```bash
python src/stock.py analyze AAPL
```

Sample output:
```
══ AAPL Technical Analysis ══
  Close:   186.40
  SMA20:   184.32   SMA50: 181.10
  EMA12:   185.93   EMA26: 183.67
  RSI14:   58.3
  MACD:    2.2600  Signal: 1.9400  Hist: 0.3200
  BB:      U=190.12  M=184.32  L=178.52  BW=0.063
  ATR14:   2.85
  VWAP:    185.21
  OBV:     4,823,200,000
  Pivot Points:
    P=186.13  R1=187.47  R2=188.80  R3=190.13
              S1=184.80  S2=183.47  S3=182.13
```

### Generate trading signals

```bash
python src/stock.py signals AAPL
```

Signals are colour-coded: 🟢 **BUY** | 🔴 **SELL** | 🟡 **NEUTRAL**

### Backtest

```bash
python src/stock.py backtest AAPL
```

### Portfolio report

```bash
python src/stock.py report AAPL
```

---

## Running Tests

```bash
pytest tests/ -v --cov=src --cov-report=term-missing
```

Test coverage includes:
- SMA exact arithmetic
- EMA recursive formula and multiplier
- RSI overbought/oversold detection
- MACD crossover detection
- Bollinger Band 2σ calculation
- Pivot point exact mathematics
- Sharpe ratio annualisation
- ATR true-range gap handling
- OBV direction tracking
- VWAP weighted average
- Max drawdown peak-to-trough
- Kelly criterion capping

---

## Architecture

```
blackroad-stock-predictor/
├── src/
│   └── stock.py          # Core engine (indicators + CLI + DB)
├── tests/
│   └── test_stock.py     # 30+ unit tests
├── stock_analytics.db    # SQLite (auto-created on first run)
└── .github/
    └── workflows/
        └── ci.yml        # Python 3.11, pytest, coverage
```

All data is persisted in a local SQLite database (`stock_analytics.db`) with an indexed `price_bars` table and a `signals` table for audit trails.

---

## References

- Wilder, J. W. (1978). *New Concepts in Technical Trading Systems*. Trend Research.
- Appel, G. (1979). *The Moving Average Convergence-Divergence Method*. Great Neck.
- Bollinger, J. (2001). *Bollinger on Bollinger Bands*. McGraw-Hill.
- Sharpe, W. F. (1966). Mutual Fund Performance. *Journal of Business*, 39(1), 119–138.
- Kelly, J. L. (1956). A New Interpretation of Information Rate. *Bell System Technical Journal*, 35(4), 917–926.

---

*© BlackRoad OS, Inc. All rights reserved.*

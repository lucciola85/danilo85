# Correlation Matrix Hunter - Quick Start Guide

## Installation

1. Copy all files to your MT5 data folder:
   - `Experts/CorrelationMatrixHunter.mq5`
   - `Include/*.mqh` files

2. Compile in MetaEditor (F7)

3. Attach to any chart

4. Enable AutoTrading

## Basic Configuration Presets

### Conservative (Recommended for Beginners)
```
Symbols: EURUSD,GBPUSD,AUDUSD,NZDUSD
Lookback Period: 60
Min Z-Score Entry: 2.5
Max Risk: 1.5%
Max Open Pairs: 2
Stop Loss: 1.5%
Take Profit: 2.5%
```

### Balanced
```
Symbols: EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD
Lookback Period: 60
Min Z-Score Entry: 2.0
Max Risk: 2.0%
Max Open Pairs: 3
Stop Loss: 2.0%
Take Profit: 3.0%
```

### Aggressive
```
Symbols: EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD
Lookback Period: 40
Min Z-Score Entry: 1.8
Max Risk: 3.0%
Max Open Pairs: 5
Stop Loss: 3.0%
Take Profit: 5.0%
```

## Key Parameters Explained

| Parameter | What It Does | Typical Range |
|-----------|--------------|---------------|
| Symbols List | Assets to monitor for correlations | 4-8 symbols |
| Lookback Period | Bars for correlation calculation | 40-100 |
| Min Z-Score Entry | Entry threshold (higher = stricter) | 1.8-3.0 |
| Max Risk % | Risk per trade | 1-3% |
| Max Open Pairs | Concurrent trades | 2-5 |
| Stop Loss % | Loss limit per pair | 1.5-3.0% |
| Take Profit % | Profit target per pair | 2.5-5.0% |

## Understanding the Visual Panel

### Heatmap Colors

**Correlation Matrix**:
- Dark Green: Strong positive correlation (>0.8)
- Light Green: Moderate positive (0.4-0.8)
- Gray: No correlation (-0.2 to 0.2)
- Red: Negative correlation (<-0.2)

**Z-Score Matrix**:
- Dark Red: Strong positive divergence (>2.0) - Symbol 1 outperforming
- Light Red: Moderate divergence (0.5-2.0)
- Gray: Normal relationship (-0.5 to 0.5)
- Blue: Negative divergence (<-0.5) - Symbol 1 underperforming
- Dark Blue: Strong negative (<-2.0)

### Market Regime Indicator

- **Stable**: Ideal for pairs trading - GO
- **Unstable**: Moderate correlations - CAUTION
- **Decoupled**: Low correlations - PAUSED
- **Transition**: Regime changing - PAUSED

## Trading Logic

### Entry Conditions
1. Z-score > Min Z-Score Entry (typically 2.0)
2. Correlation > Min Correlation (typically 0.6)
3. Not in Decoupled/Transition regime
4. Max open pairs not reached
5. Risk limits not exceeded

### Exit Conditions (Any of)
1. Z-score returns to < Exit Threshold (0.5)
2. Take profit reached (e.g., 3%)
3. Stop loss hit (e.g., 2%)
4. Maximum duration exceeded (e.g., 24h)
5. Correlation breaks down
6. Market regime changes

### Trade Direction
- **Positive Z-Score**: Symbol 1 outperformed → SHORT Symbol 1 / LONG Symbol 2
- **Negative Z-Score**: Symbol 1 underperformed → LONG Symbol 1 / SHORT Symbol 2

## Optimization Tips

### Start Here
1. Run backtest with default parameters
2. Note win rate and profit factor
3. If win rate < 55%: Increase Min Z-Score Entry
4. If too few trades: Decrease Min Z-Score Entry or add symbols
5. If drawdown too high: Reduce Max Risk %

### Advanced Optimization
Use Strategy Tester's genetic algorithm on:
- Min Z-Score Entry (1.5-3.0)
- Lookback Period (40-100)
- Take Profit % (2.0-5.0)
- Max Risk % (1.0-3.0)

### Monitor These Metrics
- **Profit Factor**: Target >1.5
- **Win Rate**: Target 60-70%
- **Max Drawdown**: Should stay within Max Drawdown parameter
- **Avg Trade Duration**: Should be reasonable (not holding forever)

## Troubleshooting

**No trades opening?**
- Lower Min Z-Score Entry to 1.8-2.0
- Add more symbols to increase opportunities
- Check if regime is paused (will show in info panel)
- Verify AutoTrading is enabled

**Too many losses?**
- Increase Min Z-Score Entry to 2.5-3.0
- Reduce Max Position Size
- Increase Stop Loss % slightly
- Verify correlations are stable (check heatmap)

**Panel not showing?**
- Set Show Visual Panel = true
- Adjust Panel X and Y positions
- Restart EA

**High margin usage?**
- Reduce Max Position Size
- Reduce Max Open Pairs
- Increase Min Z-Score Entry (fewer trades)

## Risk Management Checklist

✅ Start with demo account
✅ Test for at least 1 month
✅ Use conservative Max Risk % (1-2%)
✅ Limit Max Open Pairs (2-3 initially)
✅ Monitor free margin regularly
✅ Use VPS for 24/7 operation
✅ Set realistic profit expectations (2-5% monthly)
✅ Have stop-loss protection enabled

## Example Trade Scenario

```
Market Condition:
- EURUSD and GBPUSD normally correlate at 0.85
- Current correlation: 0.87 (still correlated)
- Z-Score: -2.3 (EURUSD underperforming relative to GBPUSD)

EA Decision:
- Entry: LONG EURUSD / SHORT GBPUSD
- Hedge Ratio: 1.2 (calculated via beta regression)
- Position: Buy 1.0 lot EURUSD, Sell 1.2 lots GBPUSD
- Expected: EURUSD catches up to GBPUSD (mean reversion)

Exit Trigger:
- Z-Score returns to -0.5 (correlation normalized)
- Or Take Profit reached (3%)
- Or Stop Loss hit (2%)
- Or 24 hours elapsed
```

## Daily Monitoring

### Check Daily
1. Visual panel showing current correlations
2. Active pairs count
3. Total profit/loss
4. Market regime indicator
5. Journal for any errors

### Weekly Review
1. Win rate (should be 60-70%)
2. Average profit per trade
3. Maximum drawdown experienced
4. Correlation stability over time
5. Adjust parameters if needed

## Contact Support

If you encounter issues:
1. Check MT5 Journal (Ctrl+T → Journal)
2. Review Expert logs
3. Verify symbol data availability
4. Ensure account has sufficient margin

---

**Remember**: Always test on demo first! Pairs trading requires discipline and proper risk management.

Good luck with your trading!

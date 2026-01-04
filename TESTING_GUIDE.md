# Correlation Matrix Hunter - Testing Guide

## Pre-Deployment Testing Checklist

### 1. Compilation Testing

#### Step 1: Verify Compilation
```
1. Open MetaEditor (F4 from MT5)
2. Open Experts/CorrelationMatrixHunter.mq5
3. Press F7 to compile
4. Check for:
   ✓ 0 errors
   ✓ 0 critical warnings
   ✓ Success message
```

Expected Output:
```
0 error(s), 0 warning(s)
'CorrelationMatrixHunter.mq5' compiled successfully
```

#### Step 2: Verify Include Files
Ensure all include files compile individually:
- CorrelationMatrix.mqh
- RiskManager.mqh
- PairsTrader.mqh
- MarketMonitor.mqh
- ExitManager.mqh
- VisualPanel.mqh

---

### 2. Demo Account Testing

#### Phase 1: Basic Functionality (Day 1-2)

**Objective**: Verify EA initializes and runs without errors

**Configuration**:
```
Symbols: EURUSD,GBPUSD
Lookback Period: 60
Min Z-Score Entry: 3.0 (very high - minimize trades)
Max Risk: 1.0%
Max Open Pairs: 1
Enable Trading: true
Show Visual Panel: true
```

**Tests**:
- [ ] EA attaches to chart successfully
- [ ] Visual panel displays correctly
- [ ] Correlation matrix updates (check timestamps)
- [ ] No errors in Journal/Experts logs
- [ ] Regime indicator shows current state
- [ ] EA runs for 24 hours without crashes

**Expected Behavior**:
- Panel updates every 5 minutes
- Regime changes are logged
- Average correlation displayed
- No unexpected errors

---

#### Phase 2: Trade Entry Testing (Day 3-5)

**Objective**: Verify EA can open trades correctly

**Configuration**:
```
Symbols: EURUSD,GBPUSD,USDJPY,AUDUSD
Lookback Period: 60
Min Z-Score Entry: 2.0 (normal threshold)
Max Risk: 2.0%
Max Open Pairs: 2
Enable Trading: true
```

**Tests**:
- [ ] EA detects Z-score divergences
- [ ] Entry conditions evaluated correctly
- [ ] Both legs of pairs trade open simultaneously
- [ ] Hedge ratio applied to second leg
- [ ] Position sizes respect risk limits
- [ ] Magic number applied correctly
- [ ] Comments include Z-score values
- [ ] Risk checks prevent over-leveraging

**Validation**:
```
Check Journal for:
"=== OPENING PAIRS TRADE ==="
"Pair: EURUSD / GBPUSD"
"Z-Score: X.XX"
"Hedge Ratio: X.XX"
"Pairs trade opened successfully!"

Check Positions:
- Two positions opened within seconds
- Opposite directions (one buy, one sell)
- Volume ratio matches hedge ratio
- Both have EA magic number
```

---

#### Phase 3: Trade Exit Testing (Day 6-8)

**Objective**: Verify exit logic works correctly

**Configuration**: Same as Phase 2

**Tests**:
- [ ] Exit on Z-score recovery
- [ ] Exit on take profit
- [ ] Exit on stop loss
- [ ] Exit on timeout (reduce max duration to 2 hours for testing)
- [ ] Exit on regime change
- [ ] Exit on correlation breakdown
- [ ] Both legs close together

**Validation**:
```
Check Journal for:
"=== CLOSING PAIRS TRADE ==="
"Reason: [Correlation Recovered / Take Profit / Stop Loss / etc.]"
"Profit: X.XX"
"Pairs trade closed successfully!"

Verify:
- Both positions closed
- Profit/loss recorded correctly
- Trade removed from active trades list
```

---

#### Phase 4: Stress Testing (Day 9-10)

**Objective**: Test EA under various conditions

**Test 4.1: Multiple Concurrent Trades**
```
Max Open Pairs: 5
Symbols: 8-10 symbols
Min Z-Score Entry: 1.8
```
- [ ] EA handles multiple pairs simultaneously
- [ ] Risk limits respected across all trades
- [ ] Visual panel updates correctly
- [ ] No performance degradation

**Test 4.2: Regime Change**
```
Pause On Regime Change: true
```
- [ ] Trading pauses in Transition regime
- [ ] Trading pauses in Decoupled regime
- [ ] Existing trades managed properly
- [ ] Trading resumes in Stable regime

**Test 4.3: Low Margin Scenario**
```
Deposit: Small account
Max Position Size: Large values
```
- [ ] EA prevents trades when margin insufficient
- [ ] Proper error messages logged
- [ ] No orphaned positions

**Test 4.4: Weekend Gap**
```
Run EA into weekend close
```
- [ ] Handles position rollovers
- [ ] Swap charges calculated correctly
- [ ] Monday open handled gracefully

---

### 3. Strategy Tester Validation

#### Backtest Configuration

**Basic Backtest**:
```
Symbol: EURUSD (or any from symbol list)
Period: 3 months
Timeframe: M15 or H1
Model: Every tick based on real ticks
Deposit: 10000
```

**Parameters to Test**:
1. Default configuration
2. Conservative configuration
3. Aggressive configuration

#### Key Metrics to Validate

**Profitability**:
- [ ] Net profit > 0 (after spread/commission)
- [ ] Profit factor > 1.3
- [ ] Expected payoff > 0

**Risk Metrics**:
- [ ] Max drawdown < Max Drawdown parameter
- [ ] Margin level never critically low
- [ ] Recovery factor > 2.0

**Trade Statistics**:
- [ ] Total trades > 50 (sufficient sample)
- [ ] Win rate: 55-75% (typical for mean reversion)
- [ ] Average trade duration < Max Duration parameter
- [ ] Both long and short trades present

**Execution Quality**:
- [ ] All pairs have both legs
- [ ] No orphaned positions
- [ ] Position sizes within limits
- [ ] Risk per trade within parameters

#### Red Flags (Fail Criteria)
- ❌ Any orphaned positions (one leg without other)
- ❌ Position size exceeding Max Position Size
- ❌ Drawdown exceeding Max Drawdown
- ❌ Runtime errors or crashes
- ❌ Zero trades over 3 months
- ❌ All losses (0% win rate)

---

### 4. Parameter Optimization

#### Optimization 1: Entry Threshold

**Variable**: Min Z-Score Entry
**Range**: 1.5 to 3.0
**Step**: 0.25
**Objective**: Maximum profit factor

**Analysis**:
- Lower values → More trades, lower quality
- Higher values → Fewer trades, higher quality
- Optimal typically between 2.0-2.5

#### Optimization 2: Lookback Period

**Variable**: Lookback Period
**Range**: 40 to 100
**Step**: 10
**Objective**: Maximum Sharpe ratio

**Analysis**:
- Lower values → More responsive, higher turnover
- Higher values → More stable, lower turnover
- Optimal varies by symbol volatility

#### Optimization 3: Risk/Reward

**Variables**: 
- Take Profit %: 2.0 to 6.0 (step 0.5)
- Stop Loss %: 1.5 to 3.0 (step 0.5)
**Objective**: Maximum recovery factor

**Analysis**:
- Ratio should be > 1.0 (reward > risk)
- Typical optimal: 1.5:1 to 2:1

---

### 5. Forward Testing Protocol

#### Week 1-2: Observation Only
```
Enable Trading: false
Show Visual Panel: true
```

**Monitor**:
- Correlation patterns
- Z-score distributions
- Regime changes
- Hypothetical entry signals

**Record**:
- Signal frequency
- Average Z-scores at signals
- Typical recovery times
- Regime distribution

#### Week 3-4: Micro Lots
```
Enable Trading: true
Max Position Size: 0.01 (micro lot)
Max Risk: 0.5%
Max Open Pairs: 1
```

**Verify**:
- Real execution matches expectations
- Slippage within acceptable range
- Spreads competitive
- Trade logic correct

#### Week 5-8: Gradual Increase
```
Week 5: Max Position 0.05, Max Risk 1.0%, Max Pairs 2
Week 6: Max Position 0.10, Max Risk 1.5%, Max Pairs 2
Week 7: Max Position 0.20, Max Risk 2.0%, Max Pairs 3
Week 8: Full production settings
```

**Track**:
- Win rate vs backtest
- Average profit per trade
- Drawdown vs expected
- Correlation stability
- Execution quality

---

### 6. Production Monitoring

#### Daily Checks
- [ ] EA running (check last update timestamp)
- [ ] Active trades count
- [ ] Current profit/loss
- [ ] Free margin level
- [ ] Any errors in log

#### Weekly Analysis
- [ ] Win rate trending as expected
- [ ] Average trade duration
- [ ] Z-score distribution at entries
- [ ] Exit reason distribution
- [ ] Correlation stability
- [ ] Regime distribution

#### Monthly Review
- [ ] Overall profitability
- [ ] Maximum drawdown experienced
- [ ] Parameter effectiveness
- [ ] Need for optimization
- [ ] Correlation changes over time

---

### 7. Common Issues and Solutions

#### Issue: No Trades Opening

**Diagnostics**:
```
Check Journal for:
- "Trading paused due to market regime: ..."
- "Position size ... exceeds maximum ..."
- "Insufficient margin: ..."

Check Visual Panel:
- Are Z-scores reaching entry threshold?
- Is regime showing Stable?
- Are correlations above minimum?
```

**Solutions**:
- Lower Min Z-Score Entry
- Increase Max Position Size
- Add more symbols
- Verify AutoTrading enabled
- Check if Pause On Regime Change = false

#### Issue: Frequent Stop Losses

**Diagnostics**:
```
Analyze losing trades:
- Entry Z-score values
- Time to stop loss
- Correlation at entry vs exit
- Regime at entry
```

**Solutions**:
- Increase Min Z-Score Entry (stricter entries)
- Increase Stop Loss % (wider stops)
- Increase Min Correlation (stronger pairs only)
- Add correlation breakdown check

#### Issue: Orphaned Positions

**Diagnostics**:
```
Check positions:
- Any positions without pairs?
- Magic number matches?
- Timestamp of opening
- Check Journal at that time
```

**Solutions**:
- Verify sufficient margin for both legs
- Check for execution errors at entry
- Increase slippage tolerance
- Review symbol trading hours

#### Issue: High Margin Usage

**Diagnostics**:
```
Check:
- Number of active pairs
- Position sizes
- Free margin percentage
```

**Solutions**:
- Reduce Max Open Pairs
- Reduce Max Position Size
- Increase account balance
- Reduce Max Risk %

---

### 8. Performance Benchmarks

#### Minimum Acceptable Performance (Demo)

```
Timeframe: 3 months
Minimum Metrics:
- Profit Factor: > 1.3
- Win Rate: > 50%
- Max Drawdown: < 15%
- Sharpe Ratio: > 0.5
- Recovery Factor: > 2.0
- Total Trades: > 50
```

#### Good Performance (Production Target)

```
Timeframe: 3 months
Target Metrics:
- Profit Factor: > 1.5
- Win Rate: 60-70%
- Max Drawdown: < 10%
- Sharpe Ratio: > 1.0
- Recovery Factor: > 3.0
- Average Trade: Positive
- Risk/Reward: > 1.5:1
```

#### Excellent Performance

```
Timeframe: 3 months
Excellent Metrics:
- Profit Factor: > 2.0
- Win Rate: > 70%
- Max Drawdown: < 8%
- Sharpe Ratio: > 1.5
- Recovery Factor: > 5.0
- Consistent monthly returns
- Low correlation to market direction
```

---

### 9. Testing Sign-Off

Before proceeding to live account:

- [ ] Compilation successful (0 errors)
- [ ] Demo testing completed (all phases)
- [ ] Backtest validation passed
- [ ] Forward testing completed (8 weeks minimum)
- [ ] Performance meets benchmarks
- [ ] Risk management verified
- [ ] No critical bugs identified
- [ ] User manual reviewed
- [ ] Emergency procedures documented
- [ ] Monitoring systems in place

**Approval**:
```
Tested By: ___________________
Date: ________________________
Approved for: [ ] Demo Only  [ ] Live Micro  [ ] Live Standard
Notes: _______________________
```

---

**Remember**: Never rush to live trading. Thorough testing saves money and prevents disasters!

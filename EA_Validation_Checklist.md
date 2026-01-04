# Correlation Matrix Hunter - EA Validation Checklist

## Pre-Deployment Validation

### 1. Compilation Checks
- [ ] Open `Experts/CorrelationMatrixHunter.mq5` in MetaEditor
- [ ] Compile with F7 - should show **0 errors, 0 warnings**
- [ ] Verify all include files are present:
  - [ ] `Include/CorrelationMatrix.mqh`
  - [ ] `Include/RiskManager.mqh`
  - [ ] `Include/PairsTrader.mqh`
  - [ ] `Include/MarketMonitor.mqh`
  - [ ] `Include/ExitManager.mqh`
  - [ ] `Include/VisualPanel.mqh`
- [ ] Verify Trade library is accessible (`#include <Trade\Trade.mqh>`)
- [ ] Check for deprecated MQL5 functions (none expected in current version)

### 2. Installation Validation
- [ ] EA appears in Navigator → Expert Advisors
- [ ] EA can be dragged onto chart successfully
- [ ] Input parameters dialog opens correctly
- [ ] All parameter groups are visible
- [ ] Help text appears for each parameter

### 3. Initialization Validation
- [ ] Attach EA to chart with default settings
- [ ] Check Experts tab for initialization messages:
  ```
  ✓ "Correlation Matrix Hunter EA - Initializing..."
  ✓ "CorrelationMatrix initialized with N symbols"
  ✓ "PairsTrader initialized with magic number: ..."
  ✓ "MarketMonitor initialized..."
  ✓ "ExitManager initialized..."
  ✓ "Visual panel initialized..."
  ✓ "Initialized Successfully"
  ```
- [ ] Verify no initialization errors in Journal tab
- [ ] Visual panel appears on chart (if enabled)
- [ ] EA smiley face shows (top right corner of chart)

### 4. Runtime Validation
- [ ] EA runs without crashes for 1 hour minimum
- [ ] Visual panel updates every 5 minutes (default)
- [ ] No errors in Experts tab
- [ ] No critical errors in Journal tab
- [ ] Memory usage stable (check Task Manager)
- [ ] Correlation matrix displays values
- [ ] Market regime indicator shows current state
- [ ] Input parameters remain as configured

### 5. Visual Panel Verification
- [ ] Panel displays at configured position (InpPanelX, InpPanelY)
- [ ] Heatmap matrix visible with correct symbol labels
- [ ] Correlation/Z-Score values displayed in cells
- [ ] Color coding works (red/green/blue for values)
- [ ] Info panel shows:
  - [ ] Market Regime
  - [ ] Average Correlation
  - [ ] Active Pairs count
  - [ ] Last Update timestamp
- [ ] Panel can be repositioned by changing parameters
- [ ] Panel clears properly on EA removal

### 6. Data Validation
- [ ] All configured symbols load historical data
- [ ] Minimum 100 bars available per symbol
- [ ] Correlation values are between -1 and 1
- [ ] Z-scores calculate correctly (check against manual calculation)
- [ ] Price data updates on new bars
- [ ] No "Insufficient data" errors

### 7. Demo Account Testing - Entry Logic
- [ ] Set conservative settings for testing:
  ```
  InpMinZScoreEntry = 2.0
  InpMaxOpenPairs = 1
  InpMaxRiskPercent = 1.0
  InpEnableTrading = true
  ```
- [ ] Wait for entry signal or manually verify conditions:
  - [ ] Z-score > Min Entry threshold
  - [ ] Correlation > Min Correlation
  - [ ] Not in Decoupled/Transition regime
  - [ ] Sufficient free margin
- [ ] When trade opens, verify:
  - [ ] Two positions opened (both legs)
  - [ ] Opposite directions (one buy, one sell)
  - [ ] Both have EA magic number
  - [ ] Volume ratio matches hedge ratio
  - [ ] Comments include Z-score value
  - [ ] Entry logged in Experts tab
  - [ ] Active Pairs count increments

### 8. Demo Account Testing - Exit Logic
- [ ] Monitor active trade for exit conditions
- [ ] Verify exits occur correctly:
  - [ ] Z-score recovery → closes both legs
  - [ ] Take profit → closes at profit target
  - [ ] Stop loss → closes at loss limit
  - [ ] Timeout → closes after max duration
  - [ ] Regime change → closes on regime shift
- [ ] Check exit is logged with reason
- [ ] Verify both legs close together (no orphaned positions)
- [ ] Active Pairs count decrements
- [ ] Profit/loss calculated correctly

### 9. Risk Management Validation
- [ ] Position sizes respect InpMaxPositionSize
- [ ] Risk per trade ≤ InpMaxRiskPercent of balance
- [ ] Margin requirements checked before opening
- [ ] Max open pairs limit enforced
- [ ] Trading stops if drawdown > InpMaxDrawdown
- [ ] No over-leveraging detected
- [ ] Free margin always positive

### 10. Backtest Verification
- [ ] Open Strategy Tester (Ctrl+R)
- [ ] Select CorrelationMatrixHunter EA
- [ ] Configure test:
  - [ ] Symbol: Any from configured list (e.g., EURUSD)
  - [ ] Period: 3 months minimum
  - [ ] Timeframe: M15 or H1
  - [ ] Model: Every tick based on real ticks
  - [ ] Deposit: 10,000 (or your target)
- [ ] Run backtest and verify:
  - [ ] No execution errors
  - [ ] Trades executed (>20 minimum for validation)
  - [ ] Both legs present for all pairs trades
  - [ ] No orphaned positions
  - [ ] Profit factor > 1.0
  - [ ] Win rate between 50-80%
  - [ ] Max drawdown < InpMaxDrawdown parameter
  - [ ] Position sizes within limits
  - [ ] Trade duration < Max Duration parameter
- [ ] Review backtest report:
  - [ ] Total trades reasonable
  - [ ] Average trade positive or break-even
  - [ ] Sharp ratio acceptable
  - [ ] Recovery factor > 1.0
- [ ] Save backtest results for comparison

### 11. Parameter Validation
Test with edge case parameters:
- [ ] **Minimum symbols** (2): Works correctly
- [ ] **Maximum symbols** (10+): No performance issues
- [ ] **Very low Z-score** (1.0): Opens trades appropriately
- [ ] **Very high Z-score** (5.0): Filters correctly, few/no trades
- [ ] **Zero risk** (0.1%): Calculates tiny positions
- [ ] **High risk** (5.0%): Respects limits
- [ ] **Max pairs = 1**: Only one trade at a time
- [ ] **Max pairs = 10**: Handles multiple trades
- [ ] **Visual panel disabled**: EA runs normally without panel

### 12. Stress Testing
- [ ] Run overnight (8+ hours) without intervention
- [ ] Multiple concurrent trades (set Max Pairs = 5)
- [ ] High volatility period (news events)
- [ ] Low liquidity period (Asian session for EUR/USD)
- [ ] Across weekend (if applicable)
- [ ] After MT5 restart
- [ ] After parameter changes (doesn't break)
- [ ] Memory leaks check (memory stable over time)

### 13. Error Handling Verification
Intentionally cause errors to verify handling:
- [ ] Insufficient margin → Trade rejected with log message
- [ ] Invalid symbol → Warning logged, continues with valid symbols
- [ ] No historical data → Error logged, initialization fails gracefully
- [ ] Network disconnection → Handles reconnection
- [ ] Position close failure → Retries or logs error
- [ ] One leg execution failure → Closes other leg, logs error

### 14. Performance Benchmarks
After 1 week of demo trading:
- [ ] Check actual vs expected:
  - [ ] Trade frequency matches parameters
  - [ ] Win rate is reasonable (50-75%)
  - [ ] Average trade duration appropriate
  - [ ] Profit factor > 1.2
  - [ ] Max drawdown within limits
- [ ] Compare with backtest results (should be similar)
- [ ] No degradation over time
- [ ] Correlation stability maintained

### 15. Documentation Verification
- [ ] README.md accurately describes EA functionality
- [ ] QuickStart.md provides clear setup instructions
- [ ] TESTING_GUIDE.md covers all test scenarios
- [ ] CONFIGURATION_PRESETS.md has working configurations
- [ ] All parameter descriptions match actual behavior
- [ ] Examples are accurate and tested

### 16. Final Validation Checklist
Before declaring production-ready:
- [ ] Zero compilation errors
- [ ] Zero runtime crashes in 1 week demo
- [ ] Zero orphaned positions observed
- [ ] Backtest shows positive results
- [ ] Demo testing shows expected behavior
- [ ] All features tested and working
- [ ] Risk management validated
- [ ] Documentation complete and accurate
- [ ] User feedback incorporated (if applicable)
- [ ] Code reviewed for best practices

## 17. Troubleshooting Common Issues

### Issue: "Failed to parse symbols list"
**Solution**: 
- Verify symbols in InpSymbolsList are comma-separated
- Check spelling of symbol names
- Ensure symbols exist in Market Watch
- Add symbols to Market Watch manually

### Issue: "Insufficient data for hedge ratio calculation"
**Solution**:
- Ensure symbols have >100 bars of history
- Verify data downloaded (Tools → Options → Charts → Max bars)
- Wait for more data to accumulate
- Reduce InpLookbackPeriod temporarily

### Issue: "Position size ... exceeds maximum"
**Solution**:
- Increase InpMaxPositionSize
- Reduce InpMaxRiskPercent
- Check account balance sufficient
- Verify symbol lot specifications

### Issue: "Trading paused due to market regime"
**Solution**:
- Check Market Monitor regime (displayed on panel)
- Set InpPauseOnRegimeChange = false if desired
- Wait for regime to stabilize (usually temporary)
- Check correlation volatility

### Issue: Visual panel not displaying
**Solution**:
- Verify InpShowVisualPanel = true
- Check panel position (InpPanelX, InpPanelY) is on screen
- Try different position values
- Remove and re-attach EA
- Check if objects are hidden (chart properties)

### Issue: Only one leg of pairs trade opens
**Solution**:
- Check free margin sufficient for both legs
- Verify both symbols tradeable (not halted)
- Check trading hours for both symbols
- Review Journal for execution errors
- Increase InpSlippage tolerance

### Issue: High margin usage / margin call risk
**Solution**:
- Reduce InpMaxOpenPairs immediately
- Reduce InpMaxPositionSize
- Reduce InpMaxRiskPercent
- Close some manual positions if any
- Deposit additional funds
- Set lower InpMinZScoreEntry for fewer trades

## 18. Resources
- **MT5 Documentation**: https://www.mql5.com/en/docs
- **Strategy Tester Guide**: https://www.metatrader5.com/en/automated-trading/strategy-tester
- **MQL5 Forum**: https://www.mql5.com/en/forum
- **Testing Guide**: See TESTING_GUIDE.md
- **Configuration Help**: See CONFIGURATION_PRESETS.md

## 19. Validation Sign-Off

**Validator Name**: _______________________
**Date**: _______________________
**MT5 Build**: _______________________
**Account Type**: [ ] Demo  [ ] Real

### Results
- Compilation: [ ] PASS  [ ] FAIL
- Initialization: [ ] PASS  [ ] FAIL
- Runtime Stability: [ ] PASS  [ ] FAIL
- Entry Logic: [ ] PASS  [ ] FAIL
- Exit Logic: [ ] PASS  [ ] FAIL
- Risk Management: [ ] PASS  [ ] FAIL
- Backtest: [ ] PASS  [ ] FAIL
- Demo Testing: [ ] PASS  [ ] FAIL

**Overall Status**: [ ] APPROVED FOR DEMO  [ ] APPROVED FOR LIVE  [ ] NEEDS WORK

**Notes**:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

**Next Steps**:
_________________________________________________________________
_________________________________________________________________
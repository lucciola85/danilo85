# Correlation Matrix Hunter - Configuration Presets

## Overview
This file contains pre-configured parameter sets for different trading scenarios. Copy the desired configuration into your EA settings.

---

## Preset 1: Conservative Forex (Major Pairs)

**Best For**: Beginners, low risk tolerance, stable returns

### Parameters
```
// Symbols Configuration
InpSymbolsList = "EURUSD,GBPUSD,AUDUSD,NZDUSD"

// Correlation Parameters
InpLookbackPeriod = 80
InpZScorePeriod = 25
InpMinZScoreEntry = 2.5
InpMaxZScoreEntry = 4.0
InpMinCorrelation = 0.7

// Risk Management
InpMaxRiskPercent = 1.5
InpMaxPositionSize = 0.5
InpMaxDrawdown = 15.0
InpMaxOpenPairs = 2

// Exit Management
InpZScoreExit = 0.6
InpCorrelationRecovery = 0.8
InpMaxTradeDurationHours = 48
InpStopLossPercent = 1.5
InpTakeProfitPercent = 2.5

// Trading Controls
InpEnableTrading = true
InpTradeOnStart = false
InpMagicNumber = 987654
InpSlippage = 10

// Market Monitor
InpMonitorUpdateFreq = 300
InpPauseOnRegimeChange = true

// Visual Panel
InpShowVisualPanel = true
InpPanelX = 10
InpPanelY = 30
InpPanelCellSize = 60
```

### Expected Behavior
- **Trade Frequency**: 2-4 trades per week
- **Win Rate**: 65-75%
- **Risk/Reward**: 1.67:1
- **Avg Trade Duration**: 24-36 hours
- **Monthly Return Target**: 3-5%
- **Max Drawdown Target**: <10%

### Rationale
- Long lookback (80) for stable correlations
- High entry threshold (2.5) for quality signals
- Strict correlation requirement (0.7)
- Low risk per trade (1.5%)
- Longer duration allowed (48h) for mean reversion
- Regime-aware trading enabled

---

## Preset 2: Balanced Multi-Currency

**Best For**: Intermediate traders, moderate risk tolerance

### Parameters
```
// Symbols Configuration
InpSymbolsList = "EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD"

// Correlation Parameters
InpLookbackPeriod = 60
InpZScorePeriod = 20
InpMinZScoreEntry = 2.0
InpMaxZScoreEntry = 3.5
InpMinCorrelation = 0.6

// Risk Management
InpMaxRiskPercent = 2.0
InpMaxPositionSize = 1.0
InpMaxDrawdown = 20.0
InpMaxOpenPairs = 3

// Exit Management
InpZScoreExit = 0.5
InpCorrelationRecovery = 0.8
InpMaxTradeDurationHours = 24
InpStopLossPercent = 2.0
InpTakeProfitPercent = 3.0

// Trading Controls
InpEnableTrading = true
InpTradeOnStart = false
InpMagicNumber = 987654
InpSlippage = 15

// Market Monitor
InpMonitorUpdateFreq = 300
InpPauseOnRegimeChange = true

// Visual Panel
InpShowVisualPanel = true
InpPanelX = 10
InpPanelY = 30
InpPanelCellSize = 55
```

### Expected Behavior
- **Trade Frequency**: 5-8 trades per week
- **Win Rate**: 60-70%
- **Risk/Reward**: 1.5:1
- **Avg Trade Duration**: 12-24 hours
- **Monthly Return Target**: 5-8%
- **Max Drawdown Target**: <15%

### Rationale
- Standard lookback (60) for responsive but stable signals
- Moderate entry threshold (2.0) for good opportunities
- 6 symbols for diversification
- Balanced risk (2.0%)
- Multiple concurrent trades (3) for efficiency

---

## Preset 3: Aggressive High-Frequency

**Best For**: Experienced traders, higher risk tolerance, active monitoring

### Parameters
```
// Symbols Configuration
InpSymbolsList = "EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD,EURGBP,EURJPY"

// Correlation Parameters
InpLookbackPeriod = 40
InpZScorePeriod = 15
InpMinZScoreEntry = 1.8
InpMaxZScoreEntry = 3.0
InpMinCorrelation = 0.55

// Risk Management
InpMaxRiskPercent = 3.0
InpMaxPositionSize = 2.0
InpMaxDrawdown = 25.0
InpMaxOpenPairs = 5

// Exit Management
InpZScoreExit = 0.4
InpCorrelationRecovery = 0.75
InpMaxTradeDurationHours = 16
InpStopLossPercent = 2.5
InpTakeProfitPercent = 4.0

// Trading Controls
InpEnableTrading = true
InpTradeOnStart = false
InpMagicNumber = 987654
InpSlippage = 20

// Market Monitor
InpMonitorUpdateFreq = 180
InpPauseOnRegimeChange = false

// Visual Panel
InpShowVisualPanel = true
InpPanelX = 10
InpPanelY = 30
InpPanelCellSize = 45
```

### Expected Behavior
- **Trade Frequency**: 10-15 trades per week
- **Win Rate**: 55-65%
- **Risk/Reward**: 1.6:1
- **Avg Trade Duration**: 6-12 hours
- **Monthly Return Target**: 8-12%
- **Max Drawdown Target**: <20%

### Rationale
- Short lookback (40) for rapid response
- Lower entry threshold (1.8) for more opportunities
- 8 symbols for maximum opportunities
- Higher risk tolerance (3.0%)
- More concurrent trades (5)
- Regime pause disabled for continuous trading
- Faster exits for quick turnover

---

## Preset 4: Cross-Asset Correlation

**Best For**: Diversified portfolios, commodities + forex

### Parameters
```
// Symbols Configuration
InpSymbolsList = "XAUUSD,XAGUSD,EURUSD,GBPUSD,AUDUSD"

// Correlation Parameters
InpLookbackPeriod = 100
InpZScorePeriod = 30
InpMinZScoreEntry = 2.2
InpMaxZScoreEntry = 4.0
InpMinCorrelation = 0.5

// Risk Management
InpMaxRiskPercent = 2.0
InpMaxPositionSize = 0.8
InpMaxDrawdown = 18.0
InpMaxOpenPairs = 2

// Exit Management
InpZScoreExit = 0.6
InpCorrelationRecovery = 0.85
InpMaxTradeDurationHours = 36
InpStopLossPercent = 2.5
InpTakeProfitPercent = 4.0

// Trading Controls
InpEnableTrading = true
InpTradeOnStart = false
InpMagicNumber = 987654
InpSlippage = 30

// Market Monitor
InpMonitorUpdateFreq = 300
InpPauseOnRegimeChange = true

// Visual Panel
InpShowVisualPanel = true
InpPanelX = 10
InpPanelY = 30
InpPanelCellSize = 65
```

### Expected Behavior
- **Trade Frequency**: 3-5 trades per week
- **Win Rate**: 60-70%
- **Risk/Reward**: 1.6:1
- **Avg Trade Duration**: 18-30 hours
- **Monthly Return Target**: 4-7%
- **Max Drawdown Target**: <12%

### Rationale
- Very long lookback (100) for cross-asset relationships
- Lower correlation requirement (0.5) as cross-asset correlations are weaker
- Includes Gold (XAUUSD) and Silver (XAGUSD)
- Commodity-forex correlations can be profitable
- Higher slippage tolerance for commodities
- Longer durations for different market hours

---

## Preset 5: EUR Focus (Regional Pairs)

**Best For**: EUR-focused trading, European session

### Parameters
```
// Symbols Configuration
InpSymbolsList = "EURUSD,EURGBP,EURJPY,EURAUD,EURCAD,EURNZD"

// Correlation Parameters
InpLookbackPeriod = 50
InpZScorePeriod = 18
InpMinZScoreEntry = 2.0
InpMaxZScoreEntry = 3.5
InpMinCorrelation = 0.65

// Risk Management
InpMaxRiskPercent = 2.0
InpMaxPositionSize = 1.0
InpMaxDrawdown = 20.0
InpMaxOpenPairs = 3

// Exit Management
InpZScoreExit = 0.5
InpCorrelationRecovery = 0.8
InpMaxTradeDurationHours = 20
InpStopLossPercent = 2.0
InpTakeProfitPercent = 3.5

// Trading Controls
InpEnableTrading = true
InpTradeOnStart = false
InpMagicNumber = 987654
InpSlippage = 12

// Market Monitor
InpMonitorUpdateFreq = 300
InpPauseOnRegimeChange = true

// Visual Panel
InpShowVisualPanel = true
InpPanelX = 10
InpPanelY = 30
InpPanelCellSize = 55
```

### Expected Behavior
- **Trade Frequency**: 6-10 trades per week
- **Win Rate**: 62-72%
- **Risk/Reward**: 1.75:1
- **Avg Trade Duration**: 10-18 hours
- **Monthly Return Target**: 5-9%
- **Max Drawdown Target**: <15%

### Rationale
- All EUR-based pairs for strong correlations
- EUR strength/weakness affects all pairs similarly
- Good for European trading hours
- Medium lookback for EUR volatility
- Higher profit target (3.5%) for EUR moves

---

## Preset 6: Night/Asian Session

**Best For**: Asian session trading, JPY pairs

### Parameters
```
// Symbols Configuration
InpSymbolsList = "USDJPY,EURJPY,GBPJPY,AUDJPY,NZDJPY"

// Correlation Parameters
InpLookbackPeriod = 60
InpZScorePeriod = 20
InpMinZScoreEntry = 2.2
InpMaxZScoreEntry = 3.8
InpMinCorrelation = 0.65

// Risk Management
InpMaxRiskPercent = 1.8
InpMaxPositionSize = 1.0
InpMaxDrawdown = 18.0
InpMaxOpenPairs = 2

// Exit Management
InpZScoreExit = 0.5
InpCorrelationRecovery = 0.8
InpMaxTradeDurationHours = 18
InpStopLossPercent = 2.2
InpTakeProfitPercent = 3.5

// Trading Controls
InpEnableTrading = true
InpTradeOnStart = false
InpMagicNumber = 987654
InpSlippage = 15

// Market Monitor
InpMonitorUpdateFreq = 300
InpPauseOnRegimeChange = true

// Visual Panel
InpShowVisualPanel = true
InpPanelX = 10
InpPanelY = 30
InpPanelCellSize = 60
```

### Expected Behavior
- **Trade Frequency**: 4-7 trades per week
- **Win Rate**: 60-70%
- **Risk/Reward**: 1.6:1
- **Avg Trade Duration**: 10-16 hours
- **Monthly Return Target**: 4-6%
- **Max Drawdown Target**: <12%

### Rationale
- JPY pairs for Asian session liquidity
- JPY correlations often strong during Tokyo hours
- Slightly higher stop loss for JPY volatility
- Lower max pairs (2) for Asian session volume
- Good for overnight trading (US/EU time)

---

## Preset 7: Backtesting Optimizer

**Best For**: Strategy testing and optimization

### Parameters
```
// Symbols Configuration
InpSymbolsList = "EURUSD,GBPUSD,USDJPY,AUDUSD"

// Correlation Parameters
InpLookbackPeriod = 60      // OPTIMIZE: 40-100, step 10
InpZScorePeriod = 20        // OPTIMIZE: 15-30, step 5
InpMinZScoreEntry = 2.0     // OPTIMIZE: 1.5-3.0, step 0.25
InpMaxZScoreEntry = 3.5
InpMinCorrelation = 0.6     // OPTIMIZE: 0.5-0.8, step 0.1

// Risk Management
InpMaxRiskPercent = 2.0     // OPTIMIZE: 1.0-3.0, step 0.5
InpMaxPositionSize = 1.0
InpMaxDrawdown = 20.0
InpMaxOpenPairs = 3

// Exit Management
InpZScoreExit = 0.5
InpCorrelationRecovery = 0.8
InpMaxTradeDurationHours = 24
InpStopLossPercent = 2.0
InpTakeProfitPercent = 3.0  // OPTIMIZE: 2.0-5.0, step 0.5

// Trading Controls
InpEnableTrading = true
InpTradeOnStart = false
InpMagicNumber = 987654
InpSlippage = 10

// Market Monitor
InpMonitorUpdateFreq = 300
InpPauseOnRegimeChange = true

// Visual Panel
InpShowVisualPanel = false  // Disable for faster backtesting
InpPanelX = 10
InpPanelY = 30
InpPanelCellSize = 60
```

### Optimization Strategy
1. **Primary Variables** (greatest impact):
   - InpMinZScoreEntry
   - InpLookbackPeriod
   - InpTakeProfitPercent

2. **Secondary Variables**:
   - InpMaxRiskPercent
   - InpMinCorrelation
   - InpZScorePeriod

3. **Optimization Method**: Genetic Algorithm
4. **Optimization Criterion**: Profit Factor or Sharpe Ratio
5. **Forward Testing**: Reserve 20% of data for validation

---

## Applying a Preset

### Method 1: Manual Entry
1. Open EA settings when attaching to chart
2. Go to "Inputs" tab
3. Copy values from preset
4. Click OK

### Method 2: Set File (MT5)
1. Load preset in EA settings
2. Click "Save" → Save as "PresetName.set"
3. Place file in `MQL5/Presets/CorrelationMatrixHunter/`
4. Load from presets dropdown when attaching EA

### Method 3: Template
1. Attach EA with desired preset
2. Save chart template
3. Apply template to other charts
4. EA settings preserved

---

## Customizing Presets

### Symbol Selection Guidelines

**High Correlation Groups**:
- EUR Majors: EURUSD, EURGBP, EURAUD, EURCAD
- GBP Majors: GBPUSD, GBPAUD, GBPCAD, GBPNZD
- JPY Crosses: USDJPY, EURJPY, GBPJPY, AUDJPY
- Commodity Currencies: AUDUSD, NZDUSD, USDCAD
- Precious Metals: XAUUSD, XAGUSD

**Avoid Mixing**:
- Don't mix highly correlated groups (e.g., all EUR pairs) - redundant
- Include diverse base currencies
- Balance liquid majors with crosses

### Parameter Tuning Tips

**Increase Trade Frequency**:
- Decrease InpMinZScoreEntry (e.g., 2.0 → 1.8)
- Increase InpMaxOpenPairs
- Add more symbols
- Decrease InpLookbackPeriod

**Improve Win Rate**:
- Increase InpMinZScoreEntry (e.g., 2.0 → 2.5)
- Increase InpMinCorrelation (e.g., 0.6 → 0.7)
- Enable InpPauseOnRegimeChange

**Reduce Drawdown**:
- Decrease InpMaxRiskPercent
- Decrease InpMaxOpenPairs
- Increase InpStopLossPercent (paradoxically can help with tight stops)
- Increase InpMinZScoreEntry

**Faster Exits**:
- Decrease InpMaxTradeDurationHours
- Decrease InpZScoreExit threshold
- Increase InpCorrelationRecovery factor

---

## Performance Tracking Template

For each preset, track these metrics weekly:

```
Preset Name: _______________
Week: _______________

Trades: _____
Wins: _____  (___%)
Losses: _____ (___%)
Avg Win: $_____
Avg Loss: $_____
Net Profit: $_____
Max Drawdown: _____% (vs Target: ____%)
Sharpe Ratio: _____
Profit Factor: _____

Notes:
_________________________________
_________________________________
```

---

## Preset Selection Decision Tree

```
Start Here
│
├─ Are you a beginner?
│  └─ YES → Use "Conservative Forex"
│  └─ NO → Continue
│
├─ Do you trade Asian session?
│  └─ YES → Use "Night/Asian Session"
│  └─ NO → Continue
│
├─ Do you trade commodities?
│  └─ YES → Use "Cross-Asset Correlation"
│  └─ NO → Continue
│
├─ Do you want high frequency?
│  └─ YES → Use "Aggressive High-Frequency"
│  └─ NO → Continue
│
└─ Default → Use "Balanced Multi-Currency"
```

---

**Remember**: All presets should be tested on demo before live trading. Adjust based on your specific broker's spreads, execution speed, and market conditions.

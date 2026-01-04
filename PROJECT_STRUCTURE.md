# Correlation Matrix Hunter - Project Structure

## Directory Layout

```
danilo85/
│
├── Experts/
│   └── CorrelationMatrixHunter.mq5       Main EA file (entry point)
│
├── Include/
│   ├── CorrelationMatrix.mqh             Correlation & Z-score calculations
│   ├── RiskManager.mqh                   Position sizing & risk controls
│   ├── PairsTrader.mqh                   Trade execution & management
│   ├── MarketMonitor.mqh                 Regime detection
│   ├── ExitManager.mqh                   Exit logic & conditions
│   └── VisualPanel.mqh                   Chart visualization
│
├── README.md                             Complete documentation
├── QuickStart.md                         Quick setup guide
├── TESTING_GUIDE.md                      Comprehensive testing procedures
├── CONFIGURATION_PRESETS.md              Pre-configured parameter sets
├── EA_Validation_Checklist.md            Validation checklist
├── LICENSE                               MIT License + Trading disclaimer
└── PROJECT_STRUCTURE.md                  This file
```

## File Descriptions

### Main EA File

**Experts/CorrelationMatrixHunter.mq5** (16,835 bytes)
- Entry point for the Expert Advisor
- Integrates all modules
- Handles OnInit(), OnTick(), OnDeinit() events
- Implements main trading logic
- Manages module coordination
- Processes input parameters
- Symbol parsing and validation

**Key Functions**:
- `OnInit()`: Initialize all modules
- `OnTick()`: Main event loop, updates modules, checks entry/exit
- `ParseSymbols()`: Parse and validate symbol list
- `UpdateModules()`: Refresh all module data
- `CheckEntryConditions()`: Evaluate new trade opportunities
- `CheckExitConditions()`: Monitor active trades for exits
- `UpdateVisualPanel()`: Refresh visual display

### Core Modules (Include/)

#### 1. CorrelationMatrix.mqh (16,783 bytes)
**Purpose**: Calculate and maintain correlation matrix

**Key Classes**:
- `CCorrelationMatrix`: Main correlation engine

**Key Methods**:
- `Init()`: Setup with symbols and periods
- `Update()`: Recalculate correlations
- `CalculateCorrelation()`: Pearson correlation coefficient
- `CalculateMean()`: Statistical mean
- `CalculateStdDev()`: Standard deviation
- `CalculateCovariance()`: Covariance between series
- `UpdateZScores()`: Calculate Z-scores from correlations
- `FindTopDivergence()`: Identify highest Z-score pair
- `FindLaggingAsset()`: Detect underperforming asset
- `GetCorrelation()`: Access correlation value
- `GetZScore()`: Access Z-score value
- `GetCorrelationMatrix()`: Full matrix export
- `GetZScoreMatrix()`: Full Z-score matrix export

**Algorithm**: 
- Rolling window correlation using Pearson coefficient
- Exponential moving average for rolling statistics
- Z-score normalization: (current - mean) / stddev

---

#### 2. RiskManager.mqh (14,080 bytes)
**Purpose**: Position sizing and risk validation

**Key Classes**:
- `CRiskManager`: Risk calculation engine

**Key Methods**:
- `Init()`: Set risk parameters
- `Update()`: Refresh account information
- `CalculatePositionSize()`: Size position based on risk
- `CalculatePairsPositionSize()`: Size both legs with hedge ratio
- `CalculateHedgeRatio()`: Beta regression for optimal ratio
- `CalculateBeta()`: Linear regression slope
- `CheckRiskLimits()`: Validate against constraints
- `GetAvailableRisk()`: Calculate available risk amount
- `GetCurrentExposure()`: Total position exposure
- `GetSymbolMarginRequired()`: Margin calculation
- `CalculateTickValue()`: Tick value per lot

**Risk Controls**:
- Maximum risk per trade (% of balance)
- Maximum position size limits
- Maximum drawdown protection
- Margin requirement validation
- Exposure monitoring across all positions
- Leverage ratio consideration

---

#### 3. PairsTrader.mqh (14,252 bytes)
**Purpose**: Execute and manage pairs trades

**Key Classes**:
- `CPairsTrader`: Trade execution manager
- `SPairsTrade`: Trade structure

**Key Methods**:
- `Init()`: Setup with magic number
- `OpenPairsTrade()`: Execute simultaneous long/short
- `OpenPosition()`: Single position execution
- `ClosePairsTrade()`: Close both legs
- `ClosePosition()`: Close single position
- `CloseAllPairsTrades()`: Emergency close all
- `UpdateTrades()`: Verify trade integrity
- `GetTrade()`: Access trade information
- `IsSymbolInTrade()`: Check if symbol is active
- `GetTotalProfit()`: Combined P&L
- `GetPairsProfit()`: Individual pair P&L

**Trade Structure** (`SPairsTrade`):
- Ticket numbers for both legs
- Symbol names
- Volumes
- Hedge ratio used
- Entry Z-score and correlation
- Trade direction
- Open time
- Magic comment

**Features**:
- Atomic pairs opening (both or none)
- Automatic hedge ratio application
- Magic number filtering
- Trade tracking and validation
- Orphaned position detection
- Error handling and retries

---

#### 4. MarketMonitor.mqh (10,072 bytes)
**Purpose**: Monitor market regime and correlation stability

**Key Classes**:
- `CMarketMonitor`: Regime detection engine

**Enumerations**:
- `ENUM_MARKET_REGIME`: Stable, Unstable, Decoupled, Transition

**Key Methods**:
- `Init()`: Setup monitoring parameters
- `Update()`: Analyze correlation matrix
- `DetermineRegime()`: Classify current regime
- `GetCurrentRegime()`: Access regime state
- `IsRegimeStable()`: Check if suitable for trading
- `RecentRegimeChange()`: Detect transitions
- `GetAverageCorrelation()`: Average across matrix
- `GetCorrelationVolatility()`: Measure stability
- `ShouldPauseTrade()`: Trading pause decision
- `GetRegimeString()`: Human-readable regime
- `UpdateCorrelationHistory()`: Circular buffer
- `CalculateCorrelationVolatility()`: Rolling volatility

**Regime Definitions**:
- **STABLE**: High avg correlation (>0.7), low volatility - Ideal
- **UNSTABLE**: Moderate correlation, higher volatility - Caution
- **DECOUPLED**: Low avg correlation (<0.3) - Pause trading
- **TRANSITION**: High volatility or recent change - Pause trading

**Thresholds**:
- Stable threshold: 0.7
- Decoupled threshold: 0.3
- Volatility threshold: 0.15

---

#### 5. ExitManager.mqh (10,139 bytes)
**Purpose**: Intelligent trade exit logic

**Key Classes**:
- `CExitManager`: Exit condition evaluator

**Enumerations**:
- `ENUM_EXIT_REASON`: Multiple exit triggers

**Key Methods**:
- `Init()`: Set exit parameters
- `ShouldExitTrade()`: Evaluate all conditions
- `CheckCorrelationRecovery()`: Mean reversion check
- `CheckThesisValidity()`: Correlation breakdown detection
- `CheckTimeout()`: Duration limit
- `CheckProfitTargets()`: TP/SL validation
- `GetExitReasonString()`: Human-readable reason
- Setters for dynamic adjustment

**Exit Conditions**:
1. **Correlation Recovered**: Z-score returns to threshold
2. **Z-Score Target**: Mean reversion achieved
3. **Thesis Invalid**: Correlation breaks down
4. **Timeout**: Maximum duration exceeded
5. **Stop Loss**: Loss limit reached
6. **Take Profit**: Profit target achieved
7. **Regime Change**: Market conditions shifted

**Exit Logic**:
- Mean reversion detection (Z-score → 0)
- Correlation sign change detection
- Correlation magnitude drop detection
- Time-based exits
- Profit/loss percentage-based exits
- Opposite Z-score movement (thesis failure)

---

#### 6. VisualPanel.mqh (11,384 bytes)
**Purpose**: Visual monitoring interface

**Key Classes**:
- `CVisualPanel`: Chart display manager

**Key Methods**:
- `Init()`: Setup panel position
- `DrawHeatmap()`: Display correlation/Z-score matrix
- `DrawInfoPanel()`: Show information text
- `UpdateInfoPanel()`: Refresh statistics
- `GetHeatmapColor()`: Color mapping for values
- `CreateLabel()`: Text object creation
- `CreateRectangle()`: Rectangle object creation
- `Show()`: Enable panel
- `Hide()`: Disable panel
- `Clear()`: Remove all objects

**Visual Elements**:
- Title label
- Symbol column headers
- Symbol row headers
- Colored matrix cells (heatmap)
- Value text overlays
- Information panel with:
  - Market regime indicator
  - Average correlation
  - Active pairs count
  - Last update timestamp

**Color Schemes**:

*Correlation Matrix*:
- Dark Green: >0.8 (strong positive)
- Light Green: 0.4-0.8 (moderate positive)
- Gray: -0.2 to 0.2 (no correlation)
- Red: <-0.2 (negative correlation)

*Z-Score Matrix*:
- Dark Red: >2.0 (strong positive divergence)
- Red: 1.0-2.0
- Light Red: 0.5-1.0
- Gray: -0.5 to 0.5 (normal)
- Light Blue: -1.0 to -0.5
- Blue: -2.0 to -1.0
- Dark Blue: <-2.0 (strong negative divergence)

---

### Documentation Files

#### README.md (16,183 bytes)
**Complete EA documentation including**:
- Overview and features
- Architecture and module descriptions
- Installation instructions
- Configuration parameters (detailed)
- Usage guide with examples
- Backtesting guide
- Risk warnings and best practices
- Troubleshooting
- Performance optimization
- Technical specifications
- Version history
- Disclaimer

#### QuickStart.md (5,549 bytes)
**Quick reference guide with**:
- Installation steps
- Basic configuration presets (Conservative, Balanced, Aggressive)
- Key parameters explained
- Visual panel color guide
- Trading logic summary
- Optimization tips
- Troubleshooting quick fixes
- Risk management checklist
- Example trade scenario
- Daily monitoring checklist

#### TESTING_GUIDE.md (10,580 bytes)
**Comprehensive testing procedures**:
- Pre-deployment checklist
- Compilation testing
- Demo account testing (4 phases)
- Strategy Tester validation
- Parameter optimization guide
- Forward testing protocol
- Production monitoring
- Common issues and solutions
- Performance benchmarks
- Testing sign-off form

#### CONFIGURATION_PRESETS.md (12,672 bytes)
**Pre-configured parameter sets**:
1. Conservative Forex (Major Pairs)
2. Balanced Multi-Currency
3. Aggressive High-Frequency
4. Cross-Asset Correlation
5. EUR Focus (Regional Pairs)
6. Night/Asian Session
7. Backtesting Optimizer

Each preset includes:
- Full parameters
- Expected behavior metrics
- Rationale for settings
- Application instructions
- Performance tracking template
- Preset selection decision tree

#### EA_Validation_Checklist.md (Updated, 9,000+ bytes)
**Detailed validation checklist**:
- Compilation checks
- Installation validation
- Initialization verification
- Runtime validation
- Visual panel verification
- Data validation
- Entry logic testing
- Exit logic testing
- Risk management validation
- Backtest verification
- Parameter validation
- Stress testing
- Error handling verification
- Performance benchmarks
- Documentation verification
- Final checklist
- Troubleshooting guide
- Validation sign-off form

#### LICENSE (2,656 bytes)
**MIT License with trading disclaimer**:
- Open source MIT license
- No warranties or guarantees
- Risk warnings
- Trading disclaimer
- Liability limitations
- Professional advice recommendation

---

## Code Statistics

### Lines of Code
- **CorrelationMatrixHunter.mq5**: ~550 lines
- **CorrelationMatrix.mqh**: ~550 lines
- **RiskManager.mqh**: ~450 lines
- **PairsTrader.mqh**: ~450 lines
- **MarketMonitor.mqh**: ~320 lines
- **ExitManager.mqh**: ~330 lines
- **VisualPanel.mqh**: ~370 lines
- **Total Code**: ~3,020 lines

### Documentation
- **Total Documentation**: ~11,000 lines
- **README**: ~550 lines
- **Testing Guide**: ~360 lines
- **Configuration Presets**: ~430 lines
- **Quick Start**: ~190 lines
- **Validation Checklist**: ~330 lines

### Total Project
- **Code + Docs**: ~14,000+ lines
- **Files**: 12 files
- **Size**: ~120 KB

---

## Key Features Implementation

### ✅ Implemented Features

1. **Real-time Correlation Analysis**
   - Rolling window calculation
   - Pearson correlation coefficient
   - Multi-symbol support (unlimited)
   - Efficient update mechanism

2. **Z-Score Divergence Detection**
   - Statistical normalization
   - Exponential moving average for rolling stats
   - Top divergence identification
   - Lagging asset detection

3. **Automated Pairs Trading**
   - Simultaneous execution (both legs)
   - Direction based on Z-score
   - Magic number filtering
   - Trade tracking and validation

4. **Dynamic Hedge Ratios**
   - Beta regression calculation
   - Price ratio adjustment
   - Reasonable range clamping

5. **Risk Management**
   - Position sizing based on risk %
   - Maximum position limits
   - Margin validation
   - Drawdown protection
   - Exposure monitoring

6. **Market Regime Detection**
   - Four regime types
   - Average correlation tracking
   - Correlation volatility measurement
   - Trading pause mechanism

7. **Intelligent Exit Logic**
   - Mean reversion (Z-score recovery)
   - Take profit / Stop loss
   - Correlation breakdown detection
   - Timeout
   - Regime change exits

8. **Visual Monitoring**
   - Heatmap matrix display
   - Color-coded values
   - Real-time updates
   - Information panel
   - Configurable position

9. **Multi-Asset Support**
   - Forex pairs
   - Commodities
   - Cross-asset correlations
   - Symbol validation

10. **Parameterization**
    - 20+ configurable parameters
    - Grouped by functionality
    - Optimization-friendly
    - Help text for each parameter

---

## Architecture Patterns

### Design Patterns Used

1. **Modular Architecture**
   - Separation of concerns
   - Each module has single responsibility
   - Clear interfaces between modules

2. **Encapsulation**
   - Private helper methods
   - Public API for each class
   - Data hiding

3. **Object-Oriented Design**
   - Classes for each major component
   - State management within classes
   - Reusable components

4. **Strategy Pattern**
   - Multiple exit strategies
   - Regime-based behavior changes
   - Parameter-driven strategies

5. **Observer Pattern**
   - Event-driven updates (OnTick)
   - Module coordination
   - State synchronization

### Data Flow

```
OnTick()
   ↓
UpdateModules()
   ↓
   ├→ CCorrelationMatrix.Update()
   │     ↓
   │  Calculate correlations & Z-scores
   │     ↓
   ├→ CMarketMonitor.Update(correlationMatrix)
   │     ↓
   │  Determine market regime
   │     ↓
   ├→ CRiskManager.Update()
   │     ↓
   │  Refresh account info
   │     ↓
   └→ CPairsTrader.UpdateTrades()
         ↓
      Verify trade integrity
         ↓
CheckExitConditions()
   ↓
   └→ For each active trade:
         ↓
      CExitManager.ShouldExitTrade()
         ↓
      If exit → ClosePairsTrade()
         ↓
CheckEntryConditions()
   ↓
   ├→ Check max pairs limit
   ├→ Check regime (CMarketMonitor)
   ├→ Find divergence (CCorrelationMatrix)
   ├→ Calculate hedge ratio (CRiskManager)
   ├→ Calculate position size (CRiskManager)
   ├→ Validate risk (CRiskManager)
   └→ Execute trade (CPairsTrader)
         ↓
UpdateVisualPanel()
   ↓
CVisualPanel.DrawHeatmap()
CVisualPanel.UpdateInfoPanel()
```

---

## Dependencies

### External Dependencies
- **MQL5 Standard Library**: `<Trade\Trade.mqh>`
- **MT5 Built-in Functions**: Symbol info, account info, position management

### Internal Dependencies
```
CorrelationMatrixHunter.mq5
   ├─ CorrelationMatrix.mqh
   ├─ RiskManager.mqh
   ├─ PairsTrader.mqh
   │     └─ Trade\Trade.mqh
   ├─ MarketMonitor.mqh
   ├─ ExitManager.mqh
   └─ VisualPanel.mqh
```

### No External Libraries Required
- All calculations implemented from scratch
- No third-party dependencies
- Pure MQL5 implementation

---

## Version Control

### Repository Structure
```
lucciola85/danilo85
├── main branch (production)
└── development branches (features)
```

### File Versions
- All files: v1.00
- Initial release: 2024

---

## Future Enhancement Possibilities

### Potential Additions (Not in Current Scope)

1. **Machine Learning Integration**
   - Neural network for regime prediction
   - Adaptive parameter optimization
   - Pattern recognition

2. **Advanced Statistics**
   - Granger causality testing
   - Cointegration analysis
   - Johansen test

3. **Portfolio Management**
   - Multi-EA coordination
   - Portfolio-level risk
   - Correlation across EAs

4. **Enhanced Visualization**
   - 3D correlation surface
   - Historical correlation charts
   - Performance dashboard

5. **News Integration**
   - Economic calendar awareness
   - News-based regime detection
   - Event filtering

6. **Alerts and Notifications**
   - Email alerts
   - Mobile notifications
   - Telegram integration

7. **Advanced Order Types**
   - Trailing stops
   - Break-even moves
   - Scaled entries/exits

8. **Backtesting Enhancements**
   - Monte Carlo simulation
   - Walk-forward optimization
   - Multi-currency backtesting

---

## Maintenance and Support

### Regular Maintenance Tasks

1. **Code Review**: Review for MQL5 updates
2. **Performance Tuning**: Optimize calculation efficiency
3. **Bug Fixes**: Address any discovered issues
4. **Documentation Updates**: Keep docs current
5. **Preset Updates**: Add new configurations based on testing

### Support Resources

- See README.md for complete documentation
- See TESTING_GUIDE.md for validation procedures
- See QuickStart.md for immediate help
- Check EA_Validation_Checklist.md for verification
- Review CONFIGURATION_PRESETS.md for setup help

---

## License and Usage

**License**: MIT License (see LICENSE file)

**Usage Rights**: 
- Free to use, modify, and distribute
- No warranties or guarantees
- Trading at your own risk
- See LICENSE for full terms

---

**End of Project Structure Documentation**

Last Updated: 2024
Version: 1.00

# Correlation Matrix Hunter EA for MetaTrader 5

## Overview

The **Correlation Matrix Hunter** is a sophisticated Expert Advisor (EA) designed for systematic pairs/correlation trading on the MetaTrader 5 platform. It analyzes real-time correlations between multiple assets, identifies statistical arbitrage opportunities through Z-score divergence analysis, and executes market-neutral pairs trades with dynamic hedge ratios.

---

## Features

### Core Functionality
- **Real-time Correlation Analysis**: Continuously calculates rolling correlations between multiple assets
- **Z-Score Divergence Detection**: Identifies pairs that have temporarily diverged from their historical correlation
- **Automated Pairs Trading**: Executes simultaneous long/short positions with optimal hedge ratios
- **Dynamic Position Sizing**: Calculates position sizes based on beta regression and risk parameters
- **Intelligent Exit Management**: Multiple exit strategies including mean reversion, stop-loss, take-profit, and timeout
- **Market Regime Detection**: Monitors market conditions and pauses trading during unstable regimes
- **Visual Heatmap Panel**: Live correlation matrix and Z-score visualization on the chart

### Multi-Asset Support
- Forex pairs (e.g., EURUSD, GBPUSD, USDJPY)
- Commodities (e.g., Gold, Silver, Oil)
- Cross-asset correlation opportunities
- Configurable symbol list for any MT5-supported instruments

---

## Architecture

The EA is built using a modular architecture with six main components:

### 1. CCorrelationMatrix (`Include/CorrelationMatrix.mqh`)
**Purpose**: Calculates and maintains the correlation matrix between all monitored assets.

**Key Methods**:
- `Init()`: Initialize with symbol list and parameters
- `Update()`: Refresh correlation matrix with latest price data
- `GetCorrelation()`: Get correlation coefficient between two symbols
- `GetZScore()`: Get Z-score for a symbol pair
- `FindTopDivergence()`: Identify the pair with highest Z-score divergence
- `FindLaggingAsset()`: Identify underperforming asset relative to a leader

**Algorithm**:
- Uses rolling window correlation calculation
- Pearson correlation coefficient: ρ = Cov(X,Y) / (σ_X × σ_Y)
- Z-score calculation: Z = (current_correlation - mean_correlation) / std_dev_correlation
- Exponential moving average for rolling statistics

### 2. CRiskManager (`Include/RiskManager.mqh`)
**Purpose**: Manages position sizing and risk calculations.

**Key Methods**:
- `Init()`: Set risk parameters
- `Update()`: Refresh account information
- `CalculatePositionSize()`: Calculate position size based on risk and stop-loss
- `CalculatePairsPositionSize()`: Calculate correlated position sizes for both legs
- `CalculateHedgeRatio()`: Calculate optimal hedge ratio using beta regression
- `CheckRiskLimits()`: Validate proposed trade against risk constraints

**Risk Controls**:
- Maximum risk per trade (% of balance)
- Maximum position size limits
- Maximum drawdown protection
- Margin requirement validation
- Exposure monitoring

### 3. CPairsTrader (`Include/PairsTrader.mqh`)
**Purpose**: Executes and manages pairs trading positions.

**Key Methods**:
- `Init()`: Initialize with magic number and slippage
- `OpenPairsTrade()`: Open simultaneous long/short positions
- `ClosePairsTrade()`: Close both legs of a pairs trade
- `UpdateTrades()`: Verify integrity of active trades
- `GetPairsProfit()`: Calculate combined profit from both legs
- `IsSymbolInTrade()`: Check if symbol is already in an active trade

**Trade Execution**:
- Atomic pairs opening (both legs or none)
- Automatic hedge ratio application
- Order retries and error handling
- Magic number filtering
- Trade tracking and monitoring

### 4. CMarketMonitor (`Include/MarketMonitor.mqh`)
**Purpose**: Monitors correlation matrix for regime changes.

**Key Methods**:
- `Init()`: Set monitoring parameters
- `Update()`: Analyze correlation matrix for regime changes
- `GetCurrentRegime()`: Get current market regime
- `ShouldPauseTrade()`: Determine if trading should be paused
- `GetAverageCorrelation()`: Get average correlation across all pairs
- `GetCorrelationVolatility()`: Measure correlation stability

**Regime Types**:
- **STABLE**: High correlations, low volatility (ideal for pairs trading)
- **UNSTABLE**: Moderate correlations with volatility (caution advised)
- **DECOUPLED**: Low correlations, independent movements (pause trading)
- **TRANSITION**: Regime is changing (pause trading)

### 5. CExitManager (`Include/ExitManager.mqh`)
**Purpose**: Implements intelligent exit logic for open trades.

**Key Methods**:
- `Init()`: Set exit parameters
- `ShouldExitTrade()`: Evaluate all exit conditions
- `GetExitReasonString()`: Get human-readable exit reason

**Exit Conditions**:
- **Correlation Recovery**: Z-score returns toward mean (target achieved)
- **Z-Score Target**: Divergence reaches exit threshold
- **Thesis Invalid**: Correlation breaks down significantly
- **Timeout**: Maximum trade duration exceeded
- **Stop Loss**: Loss limit reached
- **Take Profit**: Profit target achieved
- **Regime Change**: Market conditions changed unfavorably

### 6. CVisualPanel (`Include/VisualPanel.mqh`)
**Purpose**: Provides visual feedback and monitoring interface.

**Key Methods**:
- `Init()`: Set panel position and size
- `DrawHeatmap()`: Display correlation or Z-score matrix
- `UpdateInfoPanel()`: Show statistics and status
- `Clear()`: Remove all panel objects

**Visual Elements**:
- Color-coded correlation heatmap
- Z-score matrix with divergence highlighting
- Market regime indicator
- Active pairs counter
- Real-time profit/loss display

---

## Installation

### Prerequisites
- MetaTrader 5 build 3260 or higher
- Multiple symbols in Market Watch
- Sufficient historical data (minimum 100 bars per symbol)

### Installation Steps

1. **Copy Files to MT5 Directory**:
   ```
   MQL5/
   ├── Experts/
   │   └── CorrelationMatrixHunter.mq5
   └── Include/
       ├── CorrelationMatrix.mqh
       ├── RiskManager.mqh
       ├── PairsTrader.mqh
       ├── MarketMonitor.mqh
       ├── ExitManager.mqh
       └── VisualPanel.mqh
   ```

2. **Compile the EA**:
   - Open MetaEditor (F4 in MT5)
   - Open `Experts/CorrelationMatrixHunter.mq5`
   - Click "Compile" (F7)
   - Verify compilation succeeds with 0 errors

3. **Attach to Chart**:
   - Open any chart in MT5
   - Drag the EA from Navigator → Expert Advisors
   - Configure input parameters (see below)
   - Enable "AutoTrading" button in MT5

---

## Configuration

### Input Parameters

#### Symbols Configuration
- **InpSymbolsList**: Comma-separated list of symbols to monitor
  - Example: `"EURUSD,GBPUSD,USDJPY,AUDUSD"`
  - Minimum: 2 symbols
  - Maximum: Unlimited (practical limit ~20 for performance)

#### Correlation Parameters
- **InpLookbackPeriod** (default: 60): Number of bars for correlation calculation
  - Lower values (20-40): More responsive, captures recent relationships
  - Higher values (60-100): More stable, captures long-term relationships
  
- **InpZScorePeriod** (default: 20): Period for Z-score normalization
  - Determines how quickly Z-scores adapt to changing correlations
  
- **InpMinZScoreEntry** (default: 2.0): Minimum Z-score for trade entry
  - 2.0 = 2 standard deviations (95% confidence)
  - 2.5 = 99% confidence (fewer but stronger signals)
  
- **InpMaxZScoreEntry** (default: 4.0): Maximum Z-score for entry
  - Avoids extreme divergences that may indicate regime shifts
  
- **InpMinCorrelation** (default: 0.6): Minimum absolute correlation for pairs
  - 0.6-0.8: Moderate correlation
  - 0.8-1.0: Strong correlation (ideal for pairs trading)

#### Risk Management
- **InpMaxRiskPercent** (default: 2.0): Maximum risk per trade (% of balance)
  - Conservative: 1-2%
  - Moderate: 2-3%
  - Aggressive: 3-5%
  
- **InpMaxPositionSize** (default: 1.0): Maximum position size in lots
  - Adjust based on account size and symbol volatility
  
- **InpMaxDrawdown** (default: 20.0): Maximum account drawdown (%)
  - Trading pauses if drawdown exceeds this threshold
  
- **InpMaxOpenPairs** (default: 3): Maximum concurrent pairs trades
  - Limits exposure and diversifies across opportunities

#### Exit Management
- **InpZScoreExit** (default: 0.5): Z-score threshold for profit taking
  - Exit when divergence recovers to this level
  
- **InpCorrelationRecovery** (default: 0.8): Correlation recovery factor
  - Exit if Z-score recovers to 80% of entry level
  
- **InpMaxTradeDurationHours** (default: 24): Maximum trade duration
  - Prevents indefinite holding of divergent pairs
  
- **InpStopLossPercent** (default: 2.0): Stop loss (%)
  - Based on combined position value
  
- **InpTakeProfitPercent** (default: 3.0): Take profit (%)
  - Risk/reward ratio = 3:2 (1.5:1)

#### Trading Controls
- **InpEnableTrading** (default: true): Enable/disable auto trading
- **InpTradeOnStart** (default: false): Allow trading immediately on EA start
- **InpMagicNumber** (default: 987654): Unique identifier for EA trades
- **InpSlippage** (default: 10): Maximum allowed slippage in points

#### Market Monitor
- **InpMonitorUpdateFreq** (default: 300): Update frequency in seconds
- **InpPauseOnRegimeChange** (default: true): Pause trading during regime transitions

#### Visual Panel
- **InpShowVisualPanel** (default: true): Show/hide visual heatmap
- **InpPanelX** (default: 10): Panel X position on chart
- **InpPanelY** (default: 30): Panel Y position on chart
- **InpPanelCellSize** (default: 60): Size of each heatmap cell

---

## Usage Guide

### Basic Setup (Conservative)

```
Symbols: EURUSD,GBPUSD,AUDUSD,NZDUSD
Lookback Period: 60
Z-Score Period: 20
Min Z-Score Entry: 2.5
Max Risk: 1.5%
Max Open Pairs: 2
Stop Loss: 1.5%
Take Profit: 2.5%
```

This setup focuses on major forex pairs with conservative risk management.

### Aggressive Setup

```
Symbols: EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD
Lookback Period: 40
Z-Score Period: 15
Min Z-Score Entry: 2.0
Max Risk: 3.0%
Max Open Pairs: 5
Stop Loss: 3.0%
Take Profit: 5.0%
```

This setup allows more opportunities with higher risk tolerance.

### Cross-Asset Setup

```
Symbols: XAUUSD,XAGUSD,USOIL,EURUSD,GBPUSD
Lookback Period: 80
Z-Score Period: 25
Min Correlation: 0.5
```

Monitor correlations between commodities and forex pairs.

---

## Backtesting

### Strategy Tester Configuration

1. **Select Expert**: CorrelationMatrixHunter
2. **Symbol**: Any symbol from your list (EA monitors all configured symbols)
3. **Timeframe**: M15 or H1 (EA uses current timeframe for calculations)
4. **Period**: Minimum 3 months of data recommended
5. **Mode**: Every tick based on real ticks (most accurate)
6. **Optimization**: Genetic algorithm for parameter optimization

### Recommended Optimization Parameters

Priority parameters for optimization:
1. **InpMinZScoreEntry**: Range 1.5-3.0, Step 0.25
2. **InpLookbackPeriod**: Range 40-100, Step 10
3. **InpMaxRiskPercent**: Range 1.0-3.0, Step 0.5
4. **InpTakeProfitPercent**: Range 2.0-5.0, Step 0.5
5. **InpMinCorrelation**: Range 0.5-0.8, Step 0.1

### Performance Metrics to Monitor

- **Profit Factor**: Should be > 1.5
- **Sharpe Ratio**: Target > 1.0
- **Maximum Drawdown**: Should stay within InpMaxDrawdown
- **Win Rate**: Typically 60-70% for mean-reversion strategies
- **Average Trade Duration**: Should be < Max Trade Duration
- **Number of Trades**: Sufficient sample size (>100 trades for statistical significance)

---

## Risk Warnings

⚠️ **Important Risk Disclosures**:

1. **Correlation Breakdown**: Historical correlations can break down during market stress
2. **Slippage**: Pairs trades require simultaneous execution; slippage can impact profitability
3. **Margin Requirements**: Opening two positions simultaneously doubles margin usage
4. **Spread Costs**: Two-legged trades incur spreads on both positions
5. **Market Gaps**: Weekend or news gaps can cause one leg to execute without the other
6. **Over-fitting**: Optimize conservatively to avoid curve-fitting to historical data

### Best Practices

- Start with demo account testing
- Use conservative position sizing initially
- Monitor correlation stability over time
- Verify symbols have sufficient liquidity
- Test during different market conditions
- Keep maximum open pairs limited
- Monitor free margin closely
- Use VPS for 24/7 operation

---

## Troubleshooting

### Common Issues

**Issue**: EA doesn't open any trades
- Check if InpEnableTrading is true
- Verify AutoTrading is enabled in MT5
- Check if current Z-scores meet entry criteria
- Verify symbols have sufficient historical data
- Check if regime is paused (Decoupled/Transition)

**Issue**: Only one leg of pairs trade opens
- Check for insufficient margin
- Verify both symbols are tradeable
- Check for symbol-specific trading restrictions
- Review journal for error messages

**Issue**: Visual panel not displaying
- Verify InpShowVisualPanel is true
- Check if chart has enough space for panel
- Try different panel position (InpPanelX, InpPanelY)
- Restart EA after changing visual settings

**Issue**: Frequent stop-losses
- Increase InpStopLossPercent
- Increase InpMinZScoreEntry (stricter entry)
- Reduce InpMaxPositionSize
- Check if symbols are too volatile for current parameters

**Issue**: Trades held too long
- Reduce InpMaxTradeDurationHours
- Reduce InpZScoreExit threshold
- Enable InpPauseOnRegimeChange

---

## Performance Optimization

### For High-Frequency Monitoring
- Reduce InpMonitorUpdateFreq to 60-120 seconds
- Use lower InpLookbackPeriod (30-40)
- Enable InpPauseOnRegimeChange

### For Stability
- Increase InpLookbackPeriod to 80-100
- Increase InpMinZScoreEntry to 2.5-3.0
- Set InpMaxOpenPairs to 2-3

### For More Opportunities
- Increase symbol list (6-10 symbols)
- Reduce InpMinZScoreEntry to 1.8-2.0
- Increase InpMaxOpenPairs to 5-8
- Reduce InpMinCorrelation to 0.5

---

## Technical Specifications

### System Requirements
- **MT5 Build**: 3260+
- **Memory**: 100MB+ per EA instance
- **Processor**: Multi-core recommended for multiple symbols
- **Internet**: Stable connection for real-time data

### Performance Characteristics
- **Update Frequency**: 60 seconds (configurable)
- **Order Execution**: Synchronous (both legs or none)
- **Processing Time**: <100ms per update (typical)
- **Memory Usage**: ~2KB per symbol per bar

### Compatibility
- **Account Types**: All (Hedge/Netting)
- **Execution Types**: Market execution
- **Order Filling**: FOK (Fill or Kill)
- **Symbols**: Any MT5 tradeable instrument

---

## Version History

### Version 1.00 (Initial Release)
- Real-time correlation matrix calculation
- Z-score divergence detection
- Automated pairs trade execution
- Dynamic hedge ratio calculation
- Market regime monitoring
- Visual heatmap panel
- Comprehensive risk management
- Multiple exit strategies

---

## Support and Contact

For questions, bug reports, or feature requests:
- **Author**: Danilo Caggese
- **Copyright**: 2024
- **License**: Proprietary

---

## Disclaimer

This Expert Advisor is provided for educational and research purposes. Past performance does not guarantee future results. Trading forex, commodities, and other leveraged instruments involves significant risk of loss and may not be suitable for all investors. Use at your own risk.

**Trading Disclaimer**: The creator of this EA is not responsible for any losses incurred through the use of this software. Always test thoroughly on a demo account before live trading.

---

## Additional Resources

### Recommended Reading
- "Pairs Trading: Quantitative Methods and Analysis" by Ganapathy Vidyamurthy
- "Statistical Arbitrage" by Andrew Pole
- "Algorithmic Trading" by Ernie Chan

### Useful Links
- MQL5 Documentation: https://www.mql5.com/en/docs
- MetaTrader 5 Strategy Tester: https://www.metatrader5.com/en/automated-trading/strategy-tester

---

## Acknowledgments

This EA implements various quantitative finance concepts including:
- Pearson correlation coefficient
- Z-score normalization
- Beta regression for hedge ratios
- Mean-reversion trading strategies
- Market regime detection
- Statistical arbitrage principles

---

**End of Documentation**

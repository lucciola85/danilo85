//+------------------------------------------------------------------+
//|                                      CorrelationMatrixHunter.mq5 |
//|                                   Copyright 2024, Danilo Caggese |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Danilo Caggese"
#property link      ""
#property version   "1.00"
#property description "Correlation Matrix Hunter - Systematic Pairs Trading EA"
#property description "Analyzes real-time correlations and trades mean-reversion opportunities"

// Include custom modules
#include <CorrelationMatrix.mqh>
#include <RiskManager.mqh>
#include <PairsTrader.mqh>
#include <MarketMonitor.mqh>
#include <ExitManager.mqh>
#include <VisualPanel.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
// === Symbols Configuration ===
input string      InpSymbolsList = "EURUSD,GBPUSD,USDJPY,AUDUSD";  // Symbols to monitor (comma-separated)

// === Correlation Parameters ===
input int         InpLookbackPeriod = 60;        // Lookback Period for Correlation
input int         InpZScorePeriod = 20;          // Z-Score Period
input double      InpMinZScoreEntry = 2.0;       // Minimum Z-Score for Entry
input double      InpMaxZScoreEntry = 4.0;       // Maximum Z-Score for Entry (avoid extremes)
input double      InpMinCorrelation = 0.6;       // Minimum Correlation for Pairs

// === Risk Management ===
input double      InpMaxRiskPercent = 2.0;       // Max Risk per Trade (%)
input double      InpMaxPositionSize = 1.0;      // Maximum Position Size (lots)
input double      InpMaxDrawdown = 20.0;         // Maximum Drawdown (%)
input int         InpMaxOpenPairs = 3;           // Maximum Concurrent Pairs

// === Exit Management ===
input double      InpZScoreExit = 0.5;           // Z-Score Exit Threshold
input double      InpCorrelationRecovery = 0.8;  // Correlation Recovery Factor
input int         InpMaxTradeDurationHours = 24; // Max Trade Duration (hours)
input double      InpStopLossPercent = 2.0;      // Stop Loss (%)
input double      InpTakeProfitPercent = 3.0;    // Take Profit (%)

// === Trading Controls ===
input bool        InpEnableTrading = true;       // Enable Auto Trading
input bool        InpTradeOnStart = false;       // Allow Trading on EA Start
input ulong       InpMagicNumber = 987654;       // Magic Number
input int         InpSlippage = 10;              // Slippage (points)

// === Market Monitor ===
input int         InpMonitorUpdateFreq = 300;    // Monitor Update Frequency (seconds)
input bool        InpPauseOnRegimeChange = true; // Pause Trading on Regime Change

// === Visual Panel ===
input bool        InpShowVisualPanel = true;     // Show Visual Heatmap Panel
input int         InpPanelX = 10;                // Panel X Position
input int         InpPanelY = 30;                // Panel Y Position
input int         InpPanelCellSize = 60;         // Heatmap Cell Size

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
CCorrelationMatrix g_corrMatrix;
CRiskManager       g_riskManager;
CPairsTrader       g_pairsTrader;
CMarketMonitor     g_marketMonitor;
CExitManager       g_exitManager;
CVisualPanel       g_visualPanel;

string             g_symbols[];
int                g_symbolCount;
datetime           g_lastUpdate = 0;
datetime           g_lastTradeCheck = 0;
bool               g_initialized = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=================================================");
   Print("Correlation Matrix Hunter EA - Initializing...");
   Print("=================================================");
   
   // Parse symbols list
   if(!ParseSymbols())
   {
      Print("ERROR: Failed to parse symbols list");
      return INIT_FAILED;
   }
   
   // Initialize Correlation Matrix
   if(!g_corrMatrix.Init(g_symbols, InpLookbackPeriod, InpZScorePeriod))
   {
      Print("ERROR: Failed to initialize Correlation Matrix");
      return INIT_FAILED;
   }
   
   // Initialize Risk Manager
   if(!g_riskManager.Init(InpMaxRiskPercent, InpMaxPositionSize, InpMaxDrawdown))
   {
      Print("ERROR: Failed to initialize Risk Manager");
      return INIT_FAILED;
   }
   
   // Initialize Pairs Trader
   if(!g_pairsTrader.Init(InpMagicNumber, InpSlippage))
   {
      Print("ERROR: Failed to initialize Pairs Trader");
      return INIT_FAILED;
   }
   
   // Initialize Market Monitor
   if(!g_marketMonitor.Init(InpMonitorUpdateFreq, 100))
   {
      Print("ERROR: Failed to initialize Market Monitor");
      return INIT_FAILED;
   }
   
   // Initialize Exit Manager
   int maxDurationSeconds = InpMaxTradeDurationHours * 3600;
   if(!g_exitManager.Init(InpZScoreExit, InpCorrelationRecovery, maxDurationSeconds,
                           InpStopLossPercent, InpTakeProfitPercent))
   {
      Print("ERROR: Failed to initialize Exit Manager");
      return INIT_FAILED;
   }
   
   // Initialize Visual Panel
   if(InpShowVisualPanel)
   {
      if(!g_visualPanel.Init(InpPanelX, InpPanelY, InpPanelCellSize))
      {
         Print("WARNING: Failed to initialize Visual Panel");
         // Non-critical, continue
      }
   }
   
   g_initialized = true;
   
   Print("=================================================");
   Print("Correlation Matrix Hunter EA - Initialized Successfully");
   Print("Monitoring ", g_symbolCount, " symbols for pairs trading opportunities");
   Print("Auto Trading: ", InpEnableTrading ? "ENABLED" : "DISABLED");
   Print("=================================================");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Correlation Matrix Hunter EA - Shutting down...");
   
   // Clear visual panel
   if(InpShowVisualPanel)
      g_visualPanel.Clear();
   
   // Print final statistics
   Print("Final Statistics:");
   Print("  Active Pairs: ", g_pairsTrader.GetActiveTradesCount());
   Print("  Total Profit: ", DoubleToString(g_pairsTrader.GetTotalProfit(), 2));
   
   Print("Deinitialization reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!g_initialized)
      return;
   
   // Update on new bar or every 60 seconds
   datetime currentTime = TimeCurrent();
   if(currentTime - g_lastUpdate < 60)
      return;
   
   g_lastUpdate = currentTime;
   
   // Update all modules
   UpdateModules();
   
   // Check exit conditions for active trades
   CheckExitConditions();
   
   // Look for new trading opportunities
   if(InpEnableTrading)
   {
      if(currentTime - g_lastTradeCheck >= 300) // Check every 5 minutes
      {
         g_lastTradeCheck = currentTime;
         CheckEntryConditions();
      }
   }
   
   // Update visual panel
   if(InpShowVisualPanel && g_visualPanel.IsVisible())
      UpdateVisualPanel();
}

//+------------------------------------------------------------------+
//| Parse symbols from input string                                  |
//+------------------------------------------------------------------+
bool ParseSymbols()
{
   string symbolsList = InpSymbolsList;
   StringReplace(symbolsList, " ", ""); // Remove spaces
   
   // Split by comma
   int count = 0;
   string temp[];
   ArrayResize(temp, 50); // Max 50 symbols
   
   int pos = 0;
   while(pos >= 0)
   {
      int nextPos = StringFind(symbolsList, ",", pos);
      string symbol = "";
      
      if(nextPos >= 0)
      {
         symbol = StringSubstr(symbolsList, pos, nextPos - pos);
         pos = nextPos + 1;
      }
      else
      {
         symbol = StringSubstr(symbolsList, pos);
         pos = -1;
      }
      
      if(StringLen(symbol) > 0)
      {
         // Verify symbol exists
         if(SymbolSelect(symbol, true))
         {
            temp[count] = symbol;
            count++;
         }
         else
         {
            Print("WARNING: Symbol ", symbol, " not found in Market Watch");
         }
      }
   }
   
   if(count < 2)
   {
      Print("ERROR: At least 2 valid symbols required");
      return false;
   }
   
   g_symbolCount = count;
   ArrayResize(g_symbols, g_symbolCount);
   ArrayCopy(g_symbols, temp, 0, 0, g_symbolCount);
   
   Print("Parsed ", g_symbolCount, " symbols: ");
   for(int i = 0; i < g_symbolCount; i++)
      Print("  [", i, "] ", g_symbols[i]);
   
   return true;
}

//+------------------------------------------------------------------+
//| Update all modules with latest data                              |
//+------------------------------------------------------------------+
void UpdateModules()
{
   // Update correlation matrix
   if(!g_corrMatrix.Update())
   {
      Print("WARNING: Failed to update correlation matrix");
      return;
   }
   
   // Update risk manager
   g_riskManager.Update();
   
   // Update pairs trader
   g_pairsTrader.UpdateTrades();
   
   // Update market monitor
   double corrMatrix[][];
   g_corrMatrix.GetCorrelationMatrix(corrMatrix);
   g_marketMonitor.Update(corrMatrix, g_symbolCount);
}

//+------------------------------------------------------------------+
//| Check entry conditions for new pairs trades                      |
//+------------------------------------------------------------------+
void CheckEntryConditions()
{
   // Check if we can open new trades
   if(g_pairsTrader.GetActiveTradesCount() >= InpMaxOpenPairs)
      return;
   
   // Check market regime
   if(InpPauseOnRegimeChange && g_marketMonitor.ShouldPauseTrade())
   {
      Print("Trading paused due to market regime: ", g_marketMonitor.GetRegimeString());
      return;
   }
   
   // Find top divergence opportunity
   int symbol1Idx, symbol2Idx;
   double zScore;
   
   if(g_corrMatrix.FindTopDivergence(symbol1Idx, symbol2Idx, zScore) <= 0)
      return;
   
   // Check if Z-score is in entry range
   double absZScore = MathAbs(zScore);
   if(absZScore < InpMinZScoreEntry || absZScore > InpMaxZScoreEntry)
      return;
   
   string symbol1 = g_symbols[symbol1Idx];
   string symbol2 = g_symbols[symbol2Idx];
   
   // Check if symbols already in trade
   if(g_pairsTrader.IsSymbolInTrade(symbol1) || g_pairsTrader.IsSymbolInTrade(symbol2))
      return;
   
   // Check correlation strength
   double correlation = g_corrMatrix.GetCorrelation(symbol1Idx, symbol2Idx);
   if(MathAbs(correlation) < InpMinCorrelation)
      return;
   
   // Calculate hedge ratio
   double hedgeRatio = g_riskManager.CalculateHedgeRatio(symbol1, symbol2, InpLookbackPeriod);
   
   // Calculate position size
   double volume = g_riskManager.CalculatePairsPositionSize(symbol1, symbol2, hedgeRatio, 
                                                             InpMaxRiskPercent);
   
   if(volume <= 0)
   {
      Print("Cannot calculate valid position size for ", symbol1, " / ", symbol2);
      return;
   }
   
   // Check risk limits
   if(!g_riskManager.CheckRiskLimits(volume, symbol1))
      return;
   
   // Determine trade direction based on Z-score
   // Positive Z-score: symbol1 overperformed relative to symbol2
   // Trade: Short symbol1 (mean reversion), Long symbol2
   int direction = (zScore > 0) ? -1 : 1;
   
   // Open pairs trade
   string comment = "CorrHunter_Z" + DoubleToString(zScore, 2);
   
   Print("=== OPENING PAIRS TRADE ===");
   Print("Pair: ", symbol1, " / ", symbol2);
   Print("Z-Score: ", DoubleToString(zScore, 3));
   Print("Correlation: ", DoubleToString(correlation, 3));
   Print("Hedge Ratio: ", DoubleToString(hedgeRatio, 3));
   Print("Volume: ", DoubleToString(volume, 2));
   Print("Direction: ", (direction > 0 ? "Long/Short" : "Short/Long"));
   
   if(g_pairsTrader.OpenPairsTrade(symbol1, symbol2, volume, hedgeRatio, 
                                    zScore, correlation, direction, comment))
   {
      Print("Pairs trade opened successfully!");
   }
   else
   {
      Print("Failed to open pairs trade");
   }
}

//+------------------------------------------------------------------+
//| Check exit conditions for active trades                          |
//+------------------------------------------------------------------+
void CheckExitConditions()
{
   int activeCount = g_pairsTrader.GetActiveTradesCount();
   if(activeCount == 0)
      return;
   
   // Check each active trade from end to start (to avoid index issues on close)
   for(int i = activeCount - 1; i >= 0; i--)
   {
      SPairsTrade* trade = g_pairsTrader.GetTrade(i);
      if(trade == NULL)
         continue;
      
      // Find symbol indices
      int idx1 = -1, idx2 = -1;
      for(int j = 0; j < g_symbolCount; j++)
      {
         if(g_symbols[j] == trade.symbol1) idx1 = j;
         if(g_symbols[j] == trade.symbol2) idx2 = j;
      }
      
      if(idx1 < 0 || idx2 < 0)
         continue;
      
      // Get current metrics
      double currentZScore = g_corrMatrix.GetZScore(idx1, idx2);
      double currentCorr = g_corrMatrix.GetCorrelation(idx1, idx2);
      double currentProfit = g_pairsTrader.GetPairsProfit(i);
      
      // Calculate entry value for profit percentage
      double entryValue = 0.0;
      if(PositionSelectByTicket(trade.ticket1))
         entryValue += PositionGetDouble(POSITION_VOLUME) * 
                       SymbolInfoDouble(trade.symbol1, SYMBOL_TRADE_CONTRACT_SIZE) *
                       PositionGetDouble(POSITION_PRICE_OPEN);
      
      // Check exit conditions
      ENUM_EXIT_REASON exitReason = g_exitManager.ShouldExitTrade(
         currentZScore, trade.entryZScore,
         currentCorr, trade.entryCorr,
         trade.openTime, currentProfit, entryValue
      );
      
      // Check regime change if enabled
      if(InpPauseOnRegimeChange && g_marketMonitor.RecentRegimeChange(1800)) // 30 min
      {
         exitReason = EXIT_REGIME_CHANGE;
      }
      
      if(exitReason != EXIT_NONE)
      {
         Print("=== CLOSING PAIRS TRADE ===");
         Print("Pair: ", trade.symbol1, " / ", trade.symbol2);
         Print("Reason: ", g_exitManager.GetExitReasonString(exitReason));
         Print("Entry Z-Score: ", DoubleToString(trade.entryZScore, 3));
         Print("Current Z-Score: ", DoubleToString(currentZScore, 3));
         Print("Profit: ", DoubleToString(currentProfit, 2));
         
         if(g_pairsTrader.ClosePairsTrade(i))
         {
            Print("Pairs trade closed successfully!");
         }
         else
         {
            Print("Failed to close pairs trade");
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update visual panel with current data                            |
//+------------------------------------------------------------------+
void UpdateVisualPanel()
{
   // Get Z-score matrix for display
   double zscoreMatrix[][];
   g_corrMatrix.GetZScoreMatrix(zscoreMatrix);
   
   // Draw heatmap
   g_visualPanel.DrawHeatmap(zscoreMatrix, g_symbols, g_symbolCount, true);
   
   // Update info panel
   string regime = g_marketMonitor.GetRegimeString();
   double avgCorr = g_marketMonitor.GetAverageCorrelation();
   int activeTrades = g_pairsTrader.GetActiveTradesCount();
   
   g_visualPanel.UpdateInfoPanel(regime, avgCorr, activeTrades);
}

//+------------------------------------------------------------------+
//| Trade transaction event handler                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   // Log trade transactions for monitoring
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      if(trans.deal_type == DEAL_TYPE_BUY || trans.deal_type == DEAL_TYPE_SELL)
      {
         Print("Trade executed: ", EnumToString(trans.deal_type), 
               " ", trans.symbol, " Volume: ", trans.volume);
      }
   }
}
//+------------------------------------------------------------------+

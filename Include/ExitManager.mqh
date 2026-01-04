//+------------------------------------------------------------------+
//|                                                   ExitManager.mqh |
//|                                   Copyright 2024, Danilo Caggese |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Danilo Caggese"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Exit reason enumeration                                           |
//+------------------------------------------------------------------+
enum ENUM_EXIT_REASON
{
   EXIT_NONE,                // No exit
   EXIT_CORRELATION_RECOVERED, // Correlation returned to normal
   EXIT_ZSCORE_TARGET,       // Z-score target reached
   EXIT_THESIS_INVALID,      // Trading thesis invalidated
   EXIT_TIMEOUT,             // Maximum trade duration exceeded
   EXIT_STOP_LOSS,           // Stop loss hit
   EXIT_TAKE_PROFIT,         // Take profit hit
   EXIT_REGIME_CHANGE        // Market regime changed
};

//+------------------------------------------------------------------+
//| CExitManager Class                                                |
//| Manages intelligent exit logic for pairs trades                  |
//+------------------------------------------------------------------+
class CExitManager
{
private:
   // Exit thresholds
   double            m_zscoreExitThreshold;   // Z-score threshold for exit
   double            m_correlationRecoveryThreshold; // Correlation recovery threshold
   int               m_maxTradeDuration;      // Max duration in seconds
   double            m_stopLossPercent;       // Stop loss as % of entry
   double            m_takeProfitPercent;     // Take profit as % of entry
   
   // Tracking
   datetime          m_lastCheck;             // Last exit check timestamp
   int               m_checkFrequency;        // How often to check (seconds)
   
   // Helper methods
   bool              CheckCorrelationRecovery(double currentZScore, double entryZScore);
   bool              CheckThesisValidity(double currentCorr, double entryCorr, double minCorr);
   bool              CheckTimeout(datetime openTime);
   bool              CheckProfitTargets(double currentProfit, double entryValue);
   
public:
                     CExitManager();
                    ~CExitManager();
   
   // Initialization
   bool              Init(double zscoreExit, double corrRecovery, int maxDuration,
                         double stopLoss, double takeProfit);
   
   // Core exit logic
   ENUM_EXIT_REASON  ShouldExitTrade(double currentZScore, double entryZScore,
                                      double currentCorr, double entryCorr,
                                      datetime openTime, double currentProfit,
                                      double entryValue);
   
   // Setters for dynamic adjustment
   void              SetZScoreExitThreshold(double threshold) { m_zscoreExitThreshold = threshold; }
   void              SetMaxTradeDuration(int duration) { m_maxTradeDuration = duration; }
   void              SetStopLoss(double percent) { m_stopLossPercent = percent; }
   void              SetTakeProfit(double percent) { m_takeProfitPercent = percent; }
   
   // Getters
   double            GetZScoreExitThreshold() { return m_zscoreExitThreshold; }
   int               GetMaxTradeDuration() { return m_maxTradeDuration; }
   string            GetExitReasonString(ENUM_EXIT_REASON reason);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CExitManager::CExitManager()
{
   m_zscoreExitThreshold = 0.5;
   m_correlationRecoveryThreshold = 0.8;
   m_maxTradeDuration = 86400; // 24 hours
   m_stopLossPercent = 2.0;
   m_takeProfitPercent = 3.0;
   m_lastCheck = 0;
   m_checkFrequency = 60; // Check every minute
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CExitManager::~CExitManager()
{
}

//+------------------------------------------------------------------+
//| Initialize exit manager                                          |
//+------------------------------------------------------------------+
bool CExitManager::Init(double zscoreExit, double corrRecovery, int maxDuration,
                        double stopLoss, double takeProfit)
{
   m_zscoreExitThreshold = zscoreExit;
   m_correlationRecoveryThreshold = corrRecovery;
   m_maxTradeDuration = maxDuration;
   m_stopLossPercent = stopLoss;
   m_takeProfitPercent = takeProfit;
   
   Print("ExitManager initialized - ZScore Exit: ", m_zscoreExitThreshold,
         " | Max Duration: ", m_maxTradeDuration / 3600, "h");
   
   return true;
}

//+------------------------------------------------------------------+
//| Main exit logic - check if trade should be closed                |
//+------------------------------------------------------------------+
ENUM_EXIT_REASON CExitManager::ShouldExitTrade(double currentZScore, double entryZScore,
                                                 double currentCorr, double entryCorr,
                                                 datetime openTime, double currentProfit,
                                                 double entryValue)
{
   // Check correlation recovery (mean reversion)
   if(CheckCorrelationRecovery(currentZScore, entryZScore))
      return EXIT_CORRELATION_RECOVERED;
   
   // Check if Z-score reached target zone
   if(MathAbs(currentZScore) < m_zscoreExitThreshold)
      return EXIT_ZSCORE_TARGET;
   
   // Check profit targets (stop loss / take profit)
   if(entryValue != 0)
   {
      double profitPercent = (currentProfit / MathAbs(entryValue)) * 100.0;
      
      if(profitPercent >= m_takeProfitPercent)
         return EXIT_TAKE_PROFIT;
      
      if(profitPercent <= -m_stopLossPercent)
         return EXIT_STOP_LOSS;
   }
   
   // Check thesis validity (correlation should remain strong)
   if(!CheckThesisValidity(currentCorr, entryCorr, 0.5))
      return EXIT_THESIS_INVALID;
   
   // Check timeout
   if(CheckTimeout(openTime))
      return EXIT_TIMEOUT;
   
   // Check if Z-score diverged further (opposite direction)
   // This might indicate thesis breakdown
   if(entryZScore * currentZScore < 0 && MathAbs(currentZScore) > MathAbs(entryZScore))
      return EXIT_THESIS_INVALID;
   
   return EXIT_NONE;
}

//+------------------------------------------------------------------+
//| Check if correlation has recovered (mean reversion)              |
//+------------------------------------------------------------------+
bool CExitManager::CheckCorrelationRecovery(double currentZScore, double entryZScore)
{
   // If Z-score moved toward zero and crossed threshold
   if(MathAbs(currentZScore) < MathAbs(entryZScore) * m_correlationRecoveryThreshold)
      return true;
   
   // If Z-score crossed zero (complete reversal)
   if(entryZScore * currentZScore < 0)
      return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Check if trading thesis is still valid                           |
//+------------------------------------------------------------------+
bool CExitManager::CheckThesisValidity(double currentCorr, double entryCorr, double minCorr)
{
   // Thesis is valid if correlation remains reasonably strong
   // Significant correlation breakdown invalidates the pairs trade
   
   // If correlation dropped below minimum threshold
   if(MathAbs(currentCorr) < minCorr)
      return false;
   
   // If correlation changed sign (positive to negative or vice versa)
   if(currentCorr * entryCorr < 0)
      return false;
   
   // If correlation dropped by more than 50% from entry
   if(MathAbs(currentCorr) < MathAbs(entryCorr) * 0.5)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if trade exceeded maximum duration                         |
//+------------------------------------------------------------------+
bool CExitManager::CheckTimeout(datetime openTime)
{
   datetime currentTime = TimeCurrent();
   int duration = (int)(currentTime - openTime);
   
   return (duration >= m_maxTradeDuration);
}

//+------------------------------------------------------------------+
//| Check profit targets                                             |
//+------------------------------------------------------------------+
bool CExitManager::CheckProfitTargets(double currentProfit, double entryValue)
{
   if(entryValue == 0)
      return false;
   
   double profitPercent = (currentProfit / MathAbs(entryValue)) * 100.0;
   
   // Check stop loss
   if(profitPercent <= -m_stopLossPercent)
      return true;
   
   // Check take profit
   if(profitPercent >= m_takeProfitPercent)
      return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Get exit reason as string                                        |
//+------------------------------------------------------------------+
string CExitManager::GetExitReasonString(ENUM_EXIT_REASON reason)
{
   switch(reason)
   {
      case EXIT_NONE:                   return "None";
      case EXIT_CORRELATION_RECOVERED:  return "Correlation Recovered";
      case EXIT_ZSCORE_TARGET:          return "Z-Score Target";
      case EXIT_THESIS_INVALID:         return "Thesis Invalid";
      case EXIT_TIMEOUT:                return "Timeout";
      case EXIT_STOP_LOSS:              return "Stop Loss";
      case EXIT_TAKE_PROFIT:            return "Take Profit";
      case EXIT_REGIME_CHANGE:          return "Regime Change";
      default:                          return "Unknown";
   }
}
//+------------------------------------------------------------------+

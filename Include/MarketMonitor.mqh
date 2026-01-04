//+------------------------------------------------------------------+
//|                                                 MarketMonitor.mqh |
//|                                   Copyright 2024, Danilo Caggese |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Danilo Caggese"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Market regime enumeration                                         |
//+------------------------------------------------------------------+
enum ENUM_MARKET_REGIME
{
   REGIME_STABLE,        // High correlation, stable relationships
   REGIME_UNSTABLE,      // Moderate correlation with volatility
   REGIME_DECOUPLED,     // Low correlation, independent movements
   REGIME_TRANSITION     // Transitioning between regimes
};

//+------------------------------------------------------------------+
//| CMarketMonitor Class                                              |
//| Monitors correlation matrix and detects regime changes           |
//+------------------------------------------------------------------+
class CMarketMonitor
{
private:
   double            m_avgCorrelation;      // Average correlation across matrix
   double            m_correlationVolatility; // Volatility of correlations
   ENUM_MARKET_REGIME m_currentRegime;      // Current market regime
   ENUM_MARKET_REGIME m_previousRegime;     // Previous regime for transition detection
   datetime          m_lastRegimeChange;    // Timestamp of last regime change
   int               m_updateFrequency;     // How often to update (in seconds)
   datetime          m_lastUpdate;          // Last update timestamp
   
   // Historical tracking
   double            m_corrHistory[];       // Historical average correlations
   int               m_historySize;         // Size of history buffer
   int               m_historyIndex;        // Current index in circular buffer
   
   // Thresholds for regime detection
   double            m_stableThreshold;     // Threshold for stable regime
   double            m_decoupledThreshold;  // Threshold for decoupled regime
   double            m_volatilityThreshold; // Threshold for unstable regime
   
   // Helper methods
   void              UpdateCorrelationHistory(double avgCorr);
   double            CalculateCorrelationVolatility();
   ENUM_MARKET_REGIME DetermineRegime();
   
public:
                     CMarketMonitor();
                    ~CMarketMonitor();
   
   // Initialization
   bool              Init(int updateFrequency, int historySize);
   
   // Core functions
   bool              Update(double correlationMatrix[][], int size);
   ENUM_MARKET_REGIME GetCurrentRegime() { return m_currentRegime; }
   bool              IsRegimeStable() { return m_currentRegime == REGIME_STABLE; }
   bool              IsRegimeTransitioning() { return m_currentRegime == REGIME_TRANSITION; }
   bool              RecentRegimeChange(int seconds);
   
   // Metrics
   double            GetAverageCorrelation() { return m_avgCorrelation; }
   double            GetCorrelationVolatility() { return m_correlationVolatility; }
   string            GetRegimeString();
   
   // Alerts
   bool              ShouldPauseTrade();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CMarketMonitor::CMarketMonitor()
{
   m_avgCorrelation = 0.0;
   m_correlationVolatility = 0.0;
   m_currentRegime = REGIME_STABLE;
   m_previousRegime = REGIME_STABLE;
   m_lastRegimeChange = 0;
   m_updateFrequency = 300; // 5 minutes
   m_lastUpdate = 0;
   m_historySize = 100;
   m_historyIndex = 0;
   
   // Set default thresholds
   m_stableThreshold = 0.7;
   m_decoupledThreshold = 0.3;
   m_volatilityThreshold = 0.15;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CMarketMonitor::~CMarketMonitor()
{
}

//+------------------------------------------------------------------+
//| Initialize market monitor                                        |
//+------------------------------------------------------------------+
bool CMarketMonitor::Init(int updateFrequency, int historySize)
{
   m_updateFrequency = updateFrequency;
   m_historySize = historySize;
   
   ArrayResize(m_corrHistory, m_historySize);
   ArrayInitialize(m_corrHistory, 0.0);
   
   Print("MarketMonitor initialized with update frequency: ", m_updateFrequency, "s");
   return true;
}

//+------------------------------------------------------------------+
//| Update market monitor with latest correlation matrix             |
//+------------------------------------------------------------------+
bool CMarketMonitor::Update(double correlationMatrix[][], int size)
{
   datetime currentTime = TimeCurrent();
   
   // Check if update is needed based on frequency
   if(m_lastUpdate != 0 && (currentTime - m_lastUpdate) < m_updateFrequency)
      return true; // No update needed yet
   
   // Calculate average correlation (excluding diagonal)
   double sum = 0.0;
   int count = 0;
   
   for(int i = 0; i < size; i++)
   {
      for(int j = i + 1; j < size; j++)
      {
         sum += MathAbs(correlationMatrix[i][j]);
         count++;
      }
   }
   
   if(count > 0)
      m_avgCorrelation = sum / count;
   else
      m_avgCorrelation = 0.0;
   
   // Update history
   UpdateCorrelationHistory(m_avgCorrelation);
   
   // Calculate correlation volatility
   m_correlationVolatility = CalculateCorrelationVolatility();
   
   // Determine current regime
   ENUM_MARKET_REGIME newRegime = DetermineRegime();
   
   // Detect regime change
   if(newRegime != m_currentRegime)
   {
      m_previousRegime = m_currentRegime;
      m_currentRegime = newRegime;
      m_lastRegimeChange = currentTime;
      
      Print("Market regime changed: ", GetRegimeString());
   }
   
   m_lastUpdate = currentTime;
   return true;
}

//+------------------------------------------------------------------+
//| Update correlation history buffer                                |
//+------------------------------------------------------------------+
void CMarketMonitor::UpdateCorrelationHistory(double avgCorr)
{
   m_corrHistory[m_historyIndex] = avgCorr;
   m_historyIndex = (m_historyIndex + 1) % m_historySize;
}

//+------------------------------------------------------------------+
//| Calculate correlation volatility                                 |
//+------------------------------------------------------------------+
double CMarketMonitor::CalculateCorrelationVolatility()
{
   // Calculate standard deviation of correlation history
   int validCount = 0;
   double sum = 0.0;
   
   for(int i = 0; i < m_historySize; i++)
   {
      if(m_corrHistory[i] != 0.0)
      {
         sum += m_corrHistory[i];
         validCount++;
      }
   }
   
   if(validCount < 2)
      return 0.0;
   
   double mean = sum / validCount;
   double sumSquaredDiff = 0.0;
   
   for(int i = 0; i < m_historySize; i++)
   {
      if(m_corrHistory[i] != 0.0)
      {
         double diff = m_corrHistory[i] - mean;
         sumSquaredDiff += diff * diff;
      }
   }
   
   return MathSqrt(sumSquaredDiff / validCount);
}

//+------------------------------------------------------------------+
//| Determine market regime based on correlations                    |
//+------------------------------------------------------------------+
ENUM_MARKET_REGIME CMarketMonitor::DetermineRegime()
{
   // Stable: High average correlation, low volatility
   if(m_avgCorrelation >= m_stableThreshold && 
      m_correlationVolatility < m_volatilityThreshold)
      return REGIME_STABLE;
   
   // Decoupled: Low average correlation
   if(m_avgCorrelation < m_decoupledThreshold)
      return REGIME_DECOUPLED;
   
   // Transition: Recent regime change or high volatility
   if(m_correlationVolatility >= m_volatilityThreshold * 1.5)
      return REGIME_TRANSITION;
   
   // Unstable: Everything else
   return REGIME_UNSTABLE;
}

//+------------------------------------------------------------------+
//| Check if regime changed recently                                 |
//+------------------------------------------------------------------+
bool CMarketMonitor::RecentRegimeChange(int seconds)
{
   if(m_lastRegimeChange == 0)
      return false;
      
   return (TimeCurrent() - m_lastRegimeChange) < seconds;
}

//+------------------------------------------------------------------+
//| Get regime as string                                             |
//+------------------------------------------------------------------+
string CMarketMonitor::GetRegimeString()
{
   switch(m_currentRegime)
   {
      case REGIME_STABLE:      return "Stable";
      case REGIME_UNSTABLE:    return "Unstable";
      case REGIME_DECOUPLED:   return "Decoupled";
      case REGIME_TRANSITION:  return "Transition";
      default:                 return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| Determine if trading should be paused                            |
//+------------------------------------------------------------------+
bool CMarketMonitor::ShouldPauseTrade()
{
   // Pause trading in transition or decoupled regimes
   if(m_currentRegime == REGIME_TRANSITION || m_currentRegime == REGIME_DECOUPLED)
      return true;
   
   // Pause if recent regime change (within 5 minutes)
   if(RecentRegimeChange(300))
      return true;
   
   // Pause if correlation volatility is extremely high
   if(m_correlationVolatility > m_volatilityThreshold * 2.0)
      return true;
   
   return false;
}
//+------------------------------------------------------------------+

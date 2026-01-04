//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                                   Copyright 2024, Danilo Caggese |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Danilo Caggese"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| CRiskManager Class                                                |
//| Manages position sizing and risk calculations for pairs trading  |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
   double            m_maxRiskPercent;      // Max risk per trade as % of balance
   double            m_maxPositionSize;     // Maximum position size in lots
   double            m_accountBalance;      // Current account balance
   double            m_accountEquity;       // Current account equity
   double            m_usedMargin;          // Currently used margin
   double            m_freeMargin;          // Available free margin
   double            m_leverageRatio;       // Account leverage
   
   // Risk tracking
   int               m_openPositions;       // Number of open positions
   double            m_totalExposure;       // Total exposure across all positions
   double            m_maxDrawdownPercent;  // Maximum allowed drawdown %
   
   // Helper methods
   double            CalculateTickValue(string symbol, double volume);
   double            GetSymbolMarginRequired(string symbol, double volume);
   
public:
                     CRiskManager();
                    ~CRiskManager();
   
   // Initialization
   bool              Init(double maxRiskPercent, double maxPositionSize, double maxDrawdown);
   
   // Risk calculation
   bool              Update();
   double            CalculatePositionSize(string symbol, double stopLossPoints, double riskAmount);
   double            CalculatePairsPositionSize(string symbol1, string symbol2, double hedgeRatio, 
                                                 double riskPercent);
   bool              CheckRiskLimits(double newPositionSize, string symbol);
   double            GetAvailableRisk();
   double            GetCurrentExposure();
   
   // Beta/Hedge ratio calculation
   double            CalculateHedgeRatio(string symbol1, string symbol2, int period);
   double            CalculateBeta(double &returns1[], double &returns2[]);
   
   // Getters
   double            GetMaxRisk() { return m_maxRiskPercent; }
   double            GetAccountBalance() { return m_accountBalance; }
   double            GetAccountEquity() { return m_accountEquity; }
   double            GetFreeMargin() { return m_freeMargin; }
   int               GetOpenPositions() { return m_openPositions; }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager()
{
   m_maxRiskPercent = 2.0;
   m_maxPositionSize = 1.0;
   m_maxDrawdownPercent = 20.0;
   m_openPositions = 0;
   m_totalExposure = 0.0;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CRiskManager::~CRiskManager()
{
}

//+------------------------------------------------------------------+
//| Initialize risk manager                                          |
//+------------------------------------------------------------------+
bool CRiskManager::Init(double maxRiskPercent, double maxPositionSize, double maxDrawdown)
{
   m_maxRiskPercent = maxRiskPercent;
   m_maxPositionSize = maxPositionSize;
   m_maxDrawdownPercent = maxDrawdown;
   
   return Update();
}

//+------------------------------------------------------------------+
//| Update account information                                        |
//+------------------------------------------------------------------+
bool CRiskManager::Update()
{
   m_accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   m_accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   m_usedMargin = AccountInfoDouble(ACCOUNT_MARGIN);
   m_freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   m_leverageRatio = AccountInfoInteger(ACCOUNT_LEVERAGE);
   
   // Count open positions
   m_openPositions = PositionsTotal();
   
   // Calculate total exposure
   m_totalExposure = 0.0;
   for(int i = 0; i < m_openPositions; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         double volume = PositionGetDouble(POSITION_VOLUME);
         string symbol = PositionGetString(POSITION_SYMBOL);
         double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
         double price = PositionGetDouble(POSITION_PRICE_CURRENT);
         
         m_totalExposure += volume * contractSize * price;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Calculate position size based on risk parameters                 |
//+------------------------------------------------------------------+
double CRiskManager::CalculatePositionSize(string symbol, double stopLossPoints, double riskAmount)
{
   if(stopLossPoints <= 0)
      return 0.0;
      
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   
   if(tickSize == 0 || tickValue == 0)
      return 0.0;
   
   // Calculate risk per lot
   double riskPerLot = (stopLossPoints / tickSize) * tickValue;
   
   if(riskPerLot == 0)
      return 0.0;
      
   // Calculate position size
   double positionSize = riskAmount / riskPerLot;
   
   // Normalize to lot step
   positionSize = MathFloor(positionSize / lotStep) * lotStep;
   
   // Apply limits
   if(positionSize < minLot)
      positionSize = minLot;
   if(positionSize > maxLot)
      positionSize = maxLot;
   if(positionSize > m_maxPositionSize)
      positionSize = m_maxPositionSize;
      
   return positionSize;
}

//+------------------------------------------------------------------+
//| Calculate position sizes for pairs trade with hedge ratio        |
//+------------------------------------------------------------------+
double CRiskManager::CalculatePairsPositionSize(string symbol1, string symbol2, 
                                                 double hedgeRatio, double riskPercent)
{
   // Calculate available risk amount
   double riskAmount = m_accountBalance * (riskPercent / 100.0);
   
   // Get symbol specifications
   double minLot1 = SymbolInfoDouble(symbol1, SYMBOL_VOLUME_MIN);
   double minLot2 = SymbolInfoDouble(symbol2, SYMBOL_VOLUME_MIN);
   double lotStep1 = SymbolInfoDouble(symbol1, SYMBOL_VOLUME_STEP);
   double lotStep2 = SymbolInfoDouble(symbol2, SYMBOL_VOLUME_STEP);
   
   // Calculate base position size for symbol1
   double contractSize1 = SymbolInfoDouble(symbol1, SYMBOL_TRADE_CONTRACT_SIZE);
   double price1 = SymbolInfoDouble(symbol1, SYMBOL_BID);
   
   if(contractSize1 == 0 || price1 == 0)
      return 0.0;
   
   // Base position value
   double basePositionValue = riskAmount * 10.0; // Leverage factor
   double baseLots = basePositionValue / (contractSize1 * price1);
   
   // Normalize
   baseLots = MathFloor(baseLots / lotStep1) * lotStep1;
   
   // Apply limits
   if(baseLots < minLot1)
      baseLots = minLot1;
   if(baseLots > m_maxPositionSize)
      baseLots = m_maxPositionSize;
      
   // Check margin requirements for both legs
   double margin1 = GetSymbolMarginRequired(symbol1, baseLots);
   double margin2 = GetSymbolMarginRequired(symbol2, baseLots * hedgeRatio);
   double totalMargin = margin1 + margin2;
   
   // Ensure sufficient margin
   if(totalMargin > m_freeMargin * 0.5) // Use max 50% of free margin
   {
      double scaleFactor = (m_freeMargin * 0.5) / totalMargin;
      baseLots *= scaleFactor;
      baseLots = MathFloor(baseLots / lotStep1) * lotStep1;
   }
   
   return baseLots;
}

//+------------------------------------------------------------------+
//| Check if new position respects risk limits                       |
//+------------------------------------------------------------------+
bool CRiskManager::CheckRiskLimits(double newPositionSize, string symbol)
{
   Update();
   
   // Check drawdown limit
   double currentDrawdown = ((m_accountBalance - m_accountEquity) / m_accountBalance) * 100.0;
   if(currentDrawdown > m_maxDrawdownPercent)
   {
      Print("Risk limit exceeded: Current drawdown ", currentDrawdown, "% > Max ", m_maxDrawdownPercent, "%");
      return false;
   }
   
   // Check margin requirements
   double requiredMargin = GetSymbolMarginRequired(symbol, newPositionSize);
   if(requiredMargin > m_freeMargin)
   {
      Print("Insufficient margin: Required ", requiredMargin, " > Available ", m_freeMargin);
      return false;
   }
   
   // Check maximum position size
   if(newPositionSize > m_maxPositionSize)
   {
      Print("Position size ", newPositionSize, " exceeds maximum ", m_maxPositionSize);
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Get available risk amount                                        |
//+------------------------------------------------------------------+
double CRiskManager::GetAvailableRisk()
{
   Update();
   double availableRisk = m_accountBalance * (m_maxRiskPercent / 100.0);
   
   // Account for current exposure
   double exposureRatio = m_totalExposure / m_accountBalance;
   if(exposureRatio > 5.0) // Already highly leveraged
      availableRisk *= 0.5; // Reduce available risk
      
   return availableRisk;
}

//+------------------------------------------------------------------+
//| Get current exposure                                             |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrentExposure()
{
   return m_totalExposure;
}

//+------------------------------------------------------------------+
//| Calculate hedge ratio (beta) between two symbols                 |
//+------------------------------------------------------------------+
double CRiskManager::CalculateHedgeRatio(string symbol1, string symbol2, int period)
{
   // Get price data
   double close1[], close2[];
   ArraySetAsSeries(close1, true);
   ArraySetAsSeries(close2, true);
   
   int copied1 = CopyClose(symbol1, PERIOD_CURRENT, 0, period + 1, close1);
   int copied2 = CopyClose(symbol2, PERIOD_CURRENT, 0, period + 1, close2);
   
   if(copied1 < period + 1 || copied2 < period + 1)
   {
      Print("Error: Insufficient data for hedge ratio calculation");
      return 1.0; // Default 1:1 ratio
   }
   
   // Calculate returns
   double returns1[], returns2[];
   ArrayResize(returns1, period);
   ArrayResize(returns2, period);
   
   for(int i = 0; i < period; i++)
   {
      returns1[i] = (close1[i] - close1[i + 1]) / close1[i + 1];
      returns2[i] = (close2[i] - close2[i + 1]) / close2[i + 1];
   }
   
   // Calculate beta
   double beta = CalculateBeta(returns1, returns2);
   
   // Adjust by price ratio for practical position sizing
   double priceRatio = close1[0] / close2[0];
   double hedgeRatio = beta * priceRatio;
   
   // Clamp to reasonable range
   if(hedgeRatio < 0.1)
      hedgeRatio = 0.1;
   if(hedgeRatio > 10.0)
      hedgeRatio = 10.0;
      
   return hedgeRatio;
}

//+------------------------------------------------------------------+
//| Calculate beta (slope of linear regression)                      |
//+------------------------------------------------------------------+
double CRiskManager::CalculateBeta(double &returns1[], double &returns2[])
{
   int size = ArraySize(returns1);
   if(size == 0 || size != ArraySize(returns2))
      return 1.0;
      
   // Calculate means
   double sum1 = 0.0, sum2 = 0.0;
   for(int i = 0; i < size; i++)
   {
      sum1 += returns1[i];
      sum2 += returns2[i];
   }
   double mean1 = sum1 / size;
   double mean2 = sum2 / size;
   
   // Calculate covariance and variance
   double covariance = 0.0;
   double variance2 = 0.0;
   
   for(int i = 0; i < size; i++)
   {
      double diff1 = returns1[i] - mean1;
      double diff2 = returns2[i] - mean2;
      covariance += diff1 * diff2;
      variance2 += diff2 * diff2;
   }
   
   if(variance2 == 0)
      return 1.0;
      
   // Beta = Cov(R1, R2) / Var(R2)
   double beta = covariance / variance2;
   
   return beta;
}

//+------------------------------------------------------------------+
//| Calculate margin required for position                           |
//+------------------------------------------------------------------+
double CRiskManager::GetSymbolMarginRequired(string symbol, double volume)
{
   double margin = 0.0;
   
   if(!OrderCalcMargin(ORDER_TYPE_BUY, symbol, volume, 
                       SymbolInfoDouble(symbol, SYMBOL_ASK), margin))
   {
      Print("Error calculating margin for ", symbol);
      return 0.0;
   }
   
   return margin;
}

//+------------------------------------------------------------------+
//| Calculate tick value for symbol                                  |
//+------------------------------------------------------------------+
double CRiskManager::CalculateTickValue(string symbol, double volume)
{
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   
   if(tickValue == 0)
      return 0.0;
      
   return tickValue * volume;
}
//+------------------------------------------------------------------+

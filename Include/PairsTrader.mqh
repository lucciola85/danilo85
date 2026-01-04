//+------------------------------------------------------------------+
//|                                                   PairsTrader.mqh |
//|                                   Copyright 2024, Danilo Caggese |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Danilo Caggese"
#property link      ""
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Structure to hold pairs trade information                        |
//+------------------------------------------------------------------+
struct SPairsTrade
{
   ulong             ticket1;           // Ticket for first leg
   ulong             ticket2;           // Ticket for second leg
   string            symbol1;           // First symbol
   string            symbol2;           // Second symbol
   double            volume1;           // Volume for first leg
   double            volume2;           // Volume for second leg
   double            hedgeRatio;        // Hedge ratio used
   datetime          openTime;          // Trade open time
   double            entryZScore;       // Z-score at entry
   double            entryCorr;         // Correlation at entry
   int               tradeDirection;    // 1 = long symbol1 / short symbol2, -1 = opposite
   string            magicComment;      // Comment/identifier
};

//+------------------------------------------------------------------+
//| CPairsTrader Class                                                |
//| Executes and manages pairs trading positions                     |
//+------------------------------------------------------------------+
class CPairsTrader
{
private:
   CTrade            m_trade;           // Trade execution object
   ulong             m_magicNumber;     // Magic number for EA identification
   int               m_slippage;        // Allowed slippage in points
   SPairsTrade       m_activeTrades[];  // Array of active pairs trades
   int               m_tradeCount;      // Number of active trades
   
   // Helper methods
   bool              OpenPosition(string symbol, ENUM_ORDER_TYPE orderType, double volume, 
                                  double stopLoss, double takeProfit, string comment);
   bool              ClosePosition(ulong ticket);
   int               FindTradeIndex(ulong ticket);
   
public:
                     CPairsTrader();
                    ~CPairsTrader();
   
   // Initialization
   bool              Init(ulong magicNumber, int slippage);
   
   // Trade execution
   bool              OpenPairsTrade(string symbol1, string symbol2, double volume1, 
                                    double hedgeRatio, double zScore, double correlation,
                                    int direction, string comment);
   bool              ClosePairsTrade(int tradeIndex);
   bool              CloseAllPairsTrades();
   
   // Trade management
   bool              UpdateTrades();
   int               GetActiveTradesCount() { return m_tradeCount; }
   SPairsTrade*      GetTrade(int index);
   bool              IsSymbolInTrade(string symbol);
   
   // Position queries
   double            GetTotalProfit();
   double            GetPairsProfit(int tradeIndex);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CPairsTrader::CPairsTrader()
{
   m_magicNumber = 123456;
   m_slippage = 10;
   m_tradeCount = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CPairsTrader::~CPairsTrader()
{
}

//+------------------------------------------------------------------+
//| Initialize the pairs trader                                      |
//+------------------------------------------------------------------+
bool CPairsTrader::Init(ulong magicNumber, int slippage)
{
   m_magicNumber = magicNumber;
   m_slippage = slippage;
   
   m_trade.SetExpertMagicNumber(m_magicNumber);
   m_trade.SetDeviationInPoints(slippage);
   m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   m_trade.SetAsyncMode(false);
   
   Print("PairsTrader initialized with magic number: ", m_magicNumber);
   return true;
}

//+------------------------------------------------------------------+
//| Open a pairs trade                                               |
//+------------------------------------------------------------------+
bool CPairsTrader::OpenPairsTrade(string symbol1, string symbol2, double volume1,
                                   double hedgeRatio, double zScore, double correlation,
                                   int direction, string comment)
{
   // Determine trade direction based on Z-score
   // If Z-score > 0: symbol1 overperformed, symbol2 underperformed
   // Trade: Short symbol1 (expect mean reversion), Long symbol2
   // If Z-score < 0: opposite
   
   ENUM_ORDER_TYPE orderType1, orderType2;
   
   if(direction > 0) // Long symbol1, Short symbol2
   {
      orderType1 = ORDER_TYPE_BUY;
      orderType2 = ORDER_TYPE_SELL;
   }
   else // Short symbol1, Long symbol2
   {
      orderType1 = ORDER_TYPE_SELL;
      orderType2 = ORDER_TYPE_BUY;
   }
   
   // Calculate hedge volume
   double volume2 = volume1 * hedgeRatio;
   
   // Normalize volume2
   double minLot2 = SymbolInfoDouble(symbol2, SYMBOL_VOLUME_MIN);
   double maxLot2 = SymbolInfoDouble(symbol2, SYMBOL_VOLUME_MAX);
   double lotStep2 = SymbolInfoDouble(symbol2, SYMBOL_VOLUME_STEP);
   
   volume2 = MathFloor(volume2 / lotStep2) * lotStep2;
   if(volume2 < minLot2)
      volume2 = minLot2;
   if(volume2 > maxLot2)
      volume2 = maxLot2;
   
   // Open first leg
   string comment1 = comment + "_" + symbol1;
   if(!OpenPosition(symbol1, orderType1, volume1, 0, 0, comment1))
   {
      Print("Failed to open first leg: ", symbol1);
      return false;
   }
   
   ulong ticket1 = m_trade.ResultOrder();
   if(ticket1 == 0)
      ticket1 = m_trade.ResultDeal();
   
   // Open second leg
   string comment2 = comment + "_" + symbol2;
   if(!OpenPosition(symbol2, orderType2, volume2, 0, 0, comment2))
   {
      Print("Failed to open second leg: ", symbol2);
      // Close first leg to avoid orphaned position
      ClosePosition(ticket1);
      return false;
   }
   
   ulong ticket2 = m_trade.ResultOrder();
   if(ticket2 == 0)
      ticket2 = m_trade.ResultDeal();
   
   // Record the pairs trade
   int newIndex = m_tradeCount;
   ArrayResize(m_activeTrades, m_tradeCount + 1);
   
   m_activeTrades[newIndex].ticket1 = ticket1;
   m_activeTrades[newIndex].ticket2 = ticket2;
   m_activeTrades[newIndex].symbol1 = symbol1;
   m_activeTrades[newIndex].symbol2 = symbol2;
   m_activeTrades[newIndex].volume1 = volume1;
   m_activeTrades[newIndex].volume2 = volume2;
   m_activeTrades[newIndex].hedgeRatio = hedgeRatio;
   m_activeTrades[newIndex].openTime = TimeCurrent();
   m_activeTrades[newIndex].entryZScore = zScore;
   m_activeTrades[newIndex].entryCorr = correlation;
   m_activeTrades[newIndex].tradeDirection = direction;
   m_activeTrades[newIndex].magicComment = comment;
   
   m_tradeCount++;
   
   Print("Pairs trade opened: ", symbol1, " / ", symbol2, 
         " | Direction: ", direction, " | Z-Score: ", zScore);
   
   return true;
}

//+------------------------------------------------------------------+
//| Open a single position                                           |
//+------------------------------------------------------------------+
bool CPairsTrader::OpenPosition(string symbol, ENUM_ORDER_TYPE orderType, double volume,
                                double stopLoss, double takeProfit, string comment)
{
   double price = 0;
   
   if(orderType == ORDER_TYPE_BUY)
      price = SymbolInfoDouble(symbol, SYMBOL_ASK);
   else
      price = SymbolInfoDouble(symbol, SYMBOL_BID);
   
   if(price == 0)
   {
      Print("Error: Invalid price for ", symbol);
      return false;
   }
   
   bool result = false;
   
   if(orderType == ORDER_TYPE_BUY)
      result = m_trade.Buy(volume, symbol, price, stopLoss, takeProfit, comment);
   else if(orderType == ORDER_TYPE_SELL)
      result = m_trade.Sell(volume, symbol, price, stopLoss, takeProfit, comment);
   
   if(!result)
   {
      Print("Trade execution failed: ", m_trade.ResultRetcodeDescription());
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Close a pairs trade by index                                     |
//+------------------------------------------------------------------+
bool CPairsTrader::ClosePairsTrade(int tradeIndex)
{
   if(tradeIndex < 0 || tradeIndex >= m_tradeCount)
      return false;
   
   SPairsTrade* trade = &m_activeTrades[tradeIndex];
   
   // Close both legs
   bool success1 = ClosePosition(trade->ticket1);
   bool success2 = ClosePosition(trade->ticket2);
   
   if(success1 && success2)
   {
      Print("Pairs trade closed: ", trade->symbol1, " / ", trade->symbol2);
      
      // Remove from active trades array
      for(int i = tradeIndex; i < m_tradeCount - 1; i++)
         m_activeTrades[i] = m_activeTrades[i + 1];
      
      m_tradeCount--;
      ArrayResize(m_activeTrades, m_tradeCount);
      
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Close a single position by ticket                                |
//+------------------------------------------------------------------+
bool CPairsTrader::ClosePosition(ulong ticket)
{
   if(!PositionSelectByTicket(ticket))
      return false;
   
   string symbol = PositionGetString(POSITION_SYMBOL);
   
   if(!m_trade.PositionClose(ticket))
   {
      Print("Failed to close position ", ticket, ": ", m_trade.ResultRetcodeDescription());
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Close all active pairs trades                                    |
//+------------------------------------------------------------------+
bool CPairsTrader::CloseAllPairsTrades()
{
   int closedCount = 0;
   
   // Close from end to start to avoid index issues
   for(int i = m_tradeCount - 1; i >= 0; i--)
   {
      if(ClosePairsTrade(i))
         closedCount++;
   }
   
   Print("Closed ", closedCount, " pairs trades");
   return (closedCount > 0);
}

//+------------------------------------------------------------------+
//| Update trade information                                         |
//+------------------------------------------------------------------+
bool CPairsTrader::UpdateTrades()
{
   // Verify all active trades still exist
   for(int i = m_tradeCount - 1; i >= 0; i--)
   {
      SPairsTrade* trade = &m_activeTrades[i];
      
      bool exists1 = PositionSelectByTicket(trade->ticket1);
      bool exists2 = PositionSelectByTicket(trade->ticket2);
      
      // If either leg is closed, close the other and remove the pairs trade
      if(!exists1 || !exists2)
      {
         Print("Warning: Incomplete pairs trade detected. Cleaning up...");
         
         if(exists1)
            ClosePosition(trade->ticket1);
         if(exists2)
            ClosePosition(trade->ticket2);
         
         // Remove from array
         for(int j = i; j < m_tradeCount - 1; j++)
            m_activeTrades[j] = m_activeTrades[j + 1];
         
         m_tradeCount--;
         ArrayResize(m_activeTrades, m_tradeCount);
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Get pointer to specific trade                                    |
//+------------------------------------------------------------------+
SPairsTrade* CPairsTrader::GetTrade(int index)
{
   if(index < 0 || index >= m_tradeCount)
      return NULL;
      
   return &m_activeTrades[index];
}

//+------------------------------------------------------------------+
//| Check if symbol is part of any active trade                      |
//+------------------------------------------------------------------+
bool CPairsTrader::IsSymbolInTrade(string symbol)
{
   for(int i = 0; i < m_tradeCount; i++)
   {
      if(m_activeTrades[i].symbol1 == symbol || m_activeTrades[i].symbol2 == symbol)
         return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Calculate total profit from all pairs trades                     |
//+------------------------------------------------------------------+
double CPairsTrader::GetTotalProfit()
{
   double totalProfit = 0.0;
   
   for(int i = 0; i < m_tradeCount; i++)
   {
      totalProfit += GetPairsProfit(i);
   }
   
   return totalProfit;
}

//+------------------------------------------------------------------+
//| Calculate profit for a specific pairs trade                      |
//+------------------------------------------------------------------+
double CPairsTrader::GetPairsProfit(int tradeIndex)
{
   if(tradeIndex < 0 || tradeIndex >= m_tradeCount)
      return 0.0;
   
   SPairsTrade* trade = &m_activeTrades[tradeIndex];
   double profit = 0.0;
   
   // Get profit from first leg
   if(PositionSelectByTicket(trade->ticket1))
      profit += PositionGetDouble(POSITION_PROFIT);
   
   // Get profit from second leg
   if(PositionSelectByTicket(trade->ticket2))
      profit += PositionGetDouble(POSITION_PROFIT);
   
   return profit;
}

//+------------------------------------------------------------------+
//| Find trade index by ticket                                       |
//+------------------------------------------------------------------+
int CPairsTrader::FindTradeIndex(ulong ticket)
{
   for(int i = 0; i < m_tradeCount; i++)
   {
      if(m_activeTrades[i].ticket1 == ticket || m_activeTrades[i].ticket2 == ticket)
         return i;
   }
   
   return -1;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                            CorrelationMatrix.mqh |
//|                                   Copyright 2024, Danilo Caggese |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Danilo Caggese"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| CCorrelationMatrix Class                                          |
//| Calculates rolling correlations, Z-scores, and divergences       |
//+------------------------------------------------------------------+
class CCorrelationMatrix
{
private:
   string            m_symbols[];           // Array of symbols to track
   int               m_symbolCount;         // Number of symbols
   int               m_lookbackPeriod;      // Rolling window size for correlation
   int               m_zscorePeriod;        // Period for Z-score calculation
   double            m_correlationMatrix[][]; // Current correlation matrix
   double            m_priceData[][];       // Price data [symbol][bar]
   double            m_zscoreMatrix[][];    // Z-score for each pair
   double            m_correlationMean[][]; // Mean correlation for each pair
   double            m_correlationStdDev[][]; // StdDev correlation for each pair
   datetime          m_lastUpdate;          // Last update timestamp
   
   // Helper methods
   bool              LoadPriceData(int symbolIndex, int barCount);
   double            CalculateCorrelation(int symbol1, int symbol2);
   double            CalculateMean(double &data[]);
   double            CalculateStdDev(double &data[], double mean);
   double            CalculateCovariance(double &data1[], double &data2[], double mean1, double mean2);
   void              UpdateZScores();
   
public:
                     CCorrelationMatrix();
                    ~CCorrelationMatrix();
   
   // Initialization
   bool              Init(string &symbols[], int lookback, int zscorePeriod);
   
   // Core functions
   bool              Update();
   double            GetCorrelation(int symbol1, int symbol2);
   double            GetZScore(int symbol1, int symbol2);
   int               FindTopDivergence(int &outSymbol1, int &outSymbol2, double &outZScore);
   int               FindLaggingAsset(int leadSymbol);
   
   // Getters
   int               GetSymbolCount() { return m_symbolCount; }
   string            GetSymbol(int index) { return (index >= 0 && index < m_symbolCount) ? m_symbols[index] : ""; }
   double            GetCorrelationMean(int symbol1, int symbol2);
   double            GetCorrelationStdDev(int symbol1, int symbol2);
   
   // Matrix access
   void              GetCorrelationMatrix(double &matrix[][]);
   void              GetZScoreMatrix(double &matrix[][]);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CCorrelationMatrix::CCorrelationMatrix()
{
   m_symbolCount = 0;
   m_lookbackPeriod = 60;
   m_zscorePeriod = 20;
   m_lastUpdate = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CCorrelationMatrix::~CCorrelationMatrix()
{
}

//+------------------------------------------------------------------+
//| Initialize the correlation matrix                                |
//+------------------------------------------------------------------+
bool CCorrelationMatrix::Init(string &symbols[], int lookback, int zscorePeriod)
{
   m_symbolCount = ArraySize(symbols);
   if(m_symbolCount < 2)
   {
      Print("Error: At least 2 symbols required for correlation analysis");
      return false;
   }
   
   ArrayResize(m_symbols, m_symbolCount);
   ArrayCopy(m_symbols, symbols);
   
   m_lookbackPeriod = lookback;
   m_zscorePeriod = zscorePeriod;
   
   // Initialize matrices
   ArrayResize(m_correlationMatrix, m_symbolCount);
   ArrayResize(m_zscoreMatrix, m_symbolCount);
   ArrayResize(m_correlationMean, m_symbolCount);
   ArrayResize(m_correlationStdDev, m_symbolCount);
   
   for(int i = 0; i < m_symbolCount; i++)
   {
      ArrayResize(m_correlationMatrix[i], m_symbolCount);
      ArrayResize(m_zscoreMatrix[i], m_symbolCount);
      ArrayResize(m_correlationMean[i], m_symbolCount);
      ArrayResize(m_correlationStdDev[i], m_symbolCount);
      
      // Initialize diagonal to 1.0 (perfect correlation with self)
      m_correlationMatrix[i][i] = 1.0;
      m_zscoreMatrix[i][i] = 0.0;
   }
   
   // Initialize price data storage
   ArrayResize(m_priceData, m_symbolCount);
   for(int i = 0; i < m_symbolCount; i++)
   {
      ArrayResize(m_priceData[i], m_lookbackPeriod + m_zscorePeriod);
   }
   
   Print("CorrelationMatrix initialized with ", m_symbolCount, " symbols");
   return true;
}

//+------------------------------------------------------------------+
//| Load price data for a symbol                                     |
//+------------------------------------------------------------------+
bool CCorrelationMatrix::LoadPriceData(int symbolIndex, int barCount)
{
   if(symbolIndex < 0 || symbolIndex >= m_symbolCount)
      return false;
      
   string symbol = m_symbols[symbolIndex];
   double closeArray[];
   ArraySetAsSeries(closeArray, true);
   
   int copied = CopyClose(symbol, PERIOD_CURRENT, 0, barCount, closeArray);
   if(copied < barCount)
   {
      Print("Warning: Only ", copied, " bars copied for ", symbol);
      if(copied < m_lookbackPeriod)
         return false;
   }
   
   // Store prices in order (oldest to newest)
   for(int i = 0; i < copied; i++)
   {
      m_priceData[symbolIndex][i] = closeArray[copied - 1 - i];
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Calculate correlation between two symbols                        |
//+------------------------------------------------------------------+
double CCorrelationMatrix::CalculateCorrelation(int symbol1, int symbol2)
{
   if(symbol1 == symbol2)
      return 1.0;
      
   // Extract price data for correlation period
   double data1[], data2[];
   ArrayResize(data1, m_lookbackPeriod);
   ArrayResize(data2, m_lookbackPeriod);
   
   int startIdx = ArraySize(m_priceData[symbol1]) - m_lookbackPeriod;
   for(int i = 0; i < m_lookbackPeriod; i++)
   {
      data1[i] = m_priceData[symbol1][startIdx + i];
      data2[i] = m_priceData[symbol2][startIdx + i];
   }
   
   // Calculate means
   double mean1 = CalculateMean(data1);
   double mean2 = CalculateMean(data2);
   
   // Calculate standard deviations
   double stdDev1 = CalculateStdDev(data1, mean1);
   double stdDev2 = CalculateStdDev(data2, mean2);
   
   if(stdDev1 == 0 || stdDev2 == 0)
      return 0.0;
   
   // Calculate covariance
   double covariance = CalculateCovariance(data1, data2, mean1, mean2);
   
   // Correlation = Covariance / (StdDev1 * StdDev2)
   double correlation = covariance / (stdDev1 * stdDev2);
   
   return correlation;
}

//+------------------------------------------------------------------+
//| Calculate mean of data array                                     |
//+------------------------------------------------------------------+
double CCorrelationMatrix::CalculateMean(double &data[])
{
   int size = ArraySize(data);
   if(size == 0)
      return 0.0;
      
   double sum = 0.0;
   for(int i = 0; i < size; i++)
      sum += data[i];
      
   return sum / size;
}

//+------------------------------------------------------------------+
//| Calculate standard deviation                                     |
//+------------------------------------------------------------------+
double CCorrelationMatrix::CalculateStdDev(double &data[], double mean)
{
   int size = ArraySize(data);
   if(size == 0)
      return 0.0;
      
   double sumSquaredDiff = 0.0;
   for(int i = 0; i < size; i++)
   {
      double diff = data[i] - mean;
      sumSquaredDiff += diff * diff;
   }
   
   return MathSqrt(sumSquaredDiff / size);
}

//+------------------------------------------------------------------+
//| Calculate covariance between two datasets                        |
//+------------------------------------------------------------------+
double CCorrelationMatrix::CalculateCovariance(double &data1[], double &data2[], 
                                                double mean1, double mean2)
{
   int size = ArraySize(data1);
   if(size == 0 || size != ArraySize(data2))
      return 0.0;
      
   double sum = 0.0;
   for(int i = 0; i < size; i++)
      sum += (data1[i] - mean1) * (data2[i] - mean2);
      
   return sum / size;
}

//+------------------------------------------------------------------+
//| Update Z-scores based on correlation history                     |
//+------------------------------------------------------------------+
void CCorrelationMatrix::UpdateZScores()
{
   // For Z-score calculation, we need historical correlations
   // Simplified version: Z = (current - mean) / stddev
   
   for(int i = 0; i < m_symbolCount; i++)
   {
      for(int j = 0; j < m_symbolCount; j++)
      {
         if(i == j)
         {
            m_zscoreMatrix[i][j] = 0.0;
            continue;
         }
         
         double currentCorr = m_correlationMatrix[i][j];
         double meanCorr = m_correlationMean[i][j];
         double stdDevCorr = m_correlationStdDev[i][j];
         
         if(stdDevCorr > 0)
            m_zscoreMatrix[i][j] = (currentCorr - meanCorr) / stdDevCorr;
         else
            m_zscoreMatrix[i][j] = 0.0;
      }
   }
}

//+------------------------------------------------------------------+
//| Update correlation matrix with latest data                       |
//+------------------------------------------------------------------+
bool CCorrelationMatrix::Update()
{
   datetime currentTime = TimeCurrent();
   
   // Load latest price data for all symbols
   int requiredBars = m_lookbackPeriod + m_zscorePeriod;
   for(int i = 0; i < m_symbolCount; i++)
   {
      if(!LoadPriceData(i, requiredBars))
      {
         Print("Failed to load price data for ", m_symbols[i]);
         return false;
      }
   }
   
   // Calculate current correlations
   for(int i = 0; i < m_symbolCount; i++)
   {
      for(int j = 0; j < m_symbolCount; j++)
      {
         if(i != j)
         {
            double corr = CalculateCorrelation(i, j);
            m_correlationMatrix[i][j] = corr;
            
            // Update rolling statistics for Z-score
            // Simplified: use historical mean and stddev
            // In production, maintain a rolling buffer of correlation values
            if(m_correlationMean[i][j] == 0 && m_correlationStdDev[i][j] == 0)
            {
               // First calculation - initialize
               m_correlationMean[i][j] = corr;
               m_correlationStdDev[i][j] = 0.1; // Small initial value
            }
            else
            {
               // Exponential moving average for mean and variance
               double alpha = 2.0 / (m_zscorePeriod + 1.0);
               double oldMean = m_correlationMean[i][j];
               double oldVariance = m_correlationStdDev[i][j] * m_correlationStdDev[i][j];
               
               // Update mean
               m_correlationMean[i][j] = alpha * corr + (1 - alpha) * oldMean;
               
               // Update variance using Welford's online algorithm adapted for EMA
               double variance = (1 - alpha) * oldVariance + alpha * (corr - oldMean) * (corr - m_correlationMean[i][j]);
               m_correlationStdDev[i][j] = MathSqrt(MathAbs(variance)); // Use MathAbs to handle rounding errors
            }
         }
      }
   }
   
   // Update Z-scores
   UpdateZScores();
   
   m_lastUpdate = currentTime;
   return true;
}

//+------------------------------------------------------------------+
//| Get correlation between two symbols                              |
//+------------------------------------------------------------------+
double CCorrelationMatrix::GetCorrelation(int symbol1, int symbol2)
{
   if(symbol1 < 0 || symbol1 >= m_symbolCount || 
      symbol2 < 0 || symbol2 >= m_symbolCount)
      return 0.0;
      
   return m_correlationMatrix[symbol1][symbol2];
}

//+------------------------------------------------------------------+
//| Get Z-score between two symbols                                  |
//+------------------------------------------------------------------+
double CCorrelationMatrix::GetZScore(int symbol1, int symbol2)
{
   if(symbol1 < 0 || symbol1 >= m_symbolCount || 
      symbol2 < 0 || symbol2 >= m_symbolCount)
      return 0.0;
      
   return m_zscoreMatrix[symbol1][symbol2];
}

//+------------------------------------------------------------------+
//| Find pair with highest Z-score divergence                        |
//+------------------------------------------------------------------+
int CCorrelationMatrix::FindTopDivergence(int &outSymbol1, int &outSymbol2, double &outZScore)
{
   double maxAbsZScore = 0.0;
   int bestSymbol1 = -1;
   int bestSymbol2 = -1;
   
   for(int i = 0; i < m_symbolCount; i++)
   {
      for(int j = i + 1; j < m_symbolCount; j++)
      {
         double absZScore = MathAbs(m_zscoreMatrix[i][j]);
         if(absZScore > maxAbsZScore)
         {
            maxAbsZScore = absZScore;
            bestSymbol1 = i;
            bestSymbol2 = j;
         }
      }
   }
   
   if(bestSymbol1 >= 0 && bestSymbol2 >= 0)
   {
      outSymbol1 = bestSymbol1;
      outSymbol2 = bestSymbol2;
      outZScore = m_zscoreMatrix[bestSymbol1][bestSymbol2];
      return 1;
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Find lagging asset relative to lead symbol                       |
//+------------------------------------------------------------------+
int CCorrelationMatrix::FindLaggingAsset(int leadSymbol)
{
   if(leadSymbol < 0 || leadSymbol >= m_symbolCount)
      return -1;
      
   // Look for symbol with high correlation but negative Z-score
   // indicating temporary divergence
   double bestScore = 0.0;
   int bestSymbol = -1;
   
   for(int i = 0; i < m_symbolCount; i++)
   {
      if(i == leadSymbol)
         continue;
         
      double corr = MathAbs(m_correlationMatrix[leadSymbol][i]);
      double zscore = m_zscoreMatrix[leadSymbol][i];
      
      // High correlation but negative Z-score = lagging
      if(corr > 0.7 && zscore < -1.0)
      {
         double score = corr * MathAbs(zscore);
         if(score > bestScore)
         {
            bestScore = score;
            bestSymbol = i;
         }
      }
   }
   
   return bestSymbol;
}

//+------------------------------------------------------------------+
//| Get correlation mean                                             |
//+------------------------------------------------------------------+
double CCorrelationMatrix::GetCorrelationMean(int symbol1, int symbol2)
{
   if(symbol1 < 0 || symbol1 >= m_symbolCount || 
      symbol2 < 0 || symbol2 >= m_symbolCount)
      return 0.0;
      
   return m_correlationMean[symbol1][symbol2];
}

//+------------------------------------------------------------------+
//| Get correlation standard deviation                               |
//+------------------------------------------------------------------+
double CCorrelationMatrix::GetCorrelationStdDev(int symbol1, int symbol2)
{
   if(symbol1 < 0 || symbol1 >= m_symbolCount || 
      symbol2 < 0 || symbol2 >= m_symbolCount)
      return 0.0;
      
   return m_correlationStdDev[symbol1][symbol2];
}

//+------------------------------------------------------------------+
//| Get full correlation matrix                                      |
//+------------------------------------------------------------------+
void CCorrelationMatrix::GetCorrelationMatrix(double &matrix[][])
{
   ArrayResize(matrix, m_symbolCount);
   for(int i = 0; i < m_symbolCount; i++)
   {
      ArrayResize(matrix[i], m_symbolCount);
      ArrayCopy(matrix[i], m_correlationMatrix[i]);
   }
}

//+------------------------------------------------------------------+
//| Get full Z-score matrix                                          |
//+------------------------------------------------------------------+
void CCorrelationMatrix::GetZScoreMatrix(double &matrix[][])
{
   ArrayResize(matrix, m_symbolCount);
   for(int i = 0; i < m_symbolCount; i++)
   {
      ArrayResize(matrix[i], m_symbolCount);
      ArrayCopy(matrix[i], m_zscoreMatrix[i]);
   }
}
//+------------------------------------------------------------------+

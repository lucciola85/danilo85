//+------------------------------------------------------------------+
//|                                                   VisualPanel.mqh |
//|                                   Copyright 2024, Danilo Caggese |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Danilo Caggese"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| CVisualPanel Class                                                |
//| Creates visual heatmap and info panel for correlation monitoring |
//+------------------------------------------------------------------+
class CVisualPanel
{
private:
   string            m_chartPrefix;         // Prefix for chart objects
   int               m_panelX;              // Panel X position
   int               m_panelY;              // Panel Y position
   int               m_cellSize;            // Size of each heatmap cell
   int               m_fontSize;            // Font size for labels
   color             m_backgroundColor;     // Background color
   bool              m_isVisible;           // Panel visibility
   
   // Heatmap colors
   color             GetHeatmapColor(double value, bool isCorrelation);
   string            GetObjectName(string suffix);
   void              CreateLabel(string name, int x, int y, string text, color clr, int size);
   void              CreateRectangle(string name, int x1, int y1, int x2, int y2, color clr);
   
public:
                     CVisualPanel();
                    ~CVisualPanel();
   
   // Initialization
   bool              Init(int posX, int posY, int cellSize);
   
   // Drawing functions
   bool              DrawHeatmap(double matrix[][], string symbols[], int size, bool isZScore);
   bool              DrawInfoPanel(string info);
   bool              UpdateInfoPanel(string regimeInfo, double avgCorr, int activeTrades);
   
   // Control
   void              Show();
   void              Hide();
   void              Clear();
   bool              IsVisible() { return m_isVisible; }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CVisualPanel::CVisualPanel()
{
   m_chartPrefix = "CorrHunter_";
   m_panelX = 10;
   m_panelY = 30;
   m_cellSize = 60;
   m_fontSize = 8;
   m_backgroundColor = clrWhite;
   m_isVisible = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CVisualPanel::~CVisualPanel()
{
   Clear();
}

//+------------------------------------------------------------------+
//| Initialize visual panel                                          |
//+------------------------------------------------------------------+
bool CVisualPanel::Init(int posX, int posY, int cellSize)
{
   m_panelX = posX;
   m_panelY = posY;
   m_cellSize = cellSize;
   
   Clear();
   m_isVisible = true;
   
   Print("Visual panel initialized at position (", m_panelX, ", ", m_panelY, ")");
   return true;
}

//+------------------------------------------------------------------+
//| Get object name with prefix                                      |
//+------------------------------------------------------------------+
string CVisualPanel::GetObjectName(string suffix)
{
   return m_chartPrefix + suffix;
}

//+------------------------------------------------------------------+
//| Create text label on chart                                       |
//+------------------------------------------------------------------+
void CVisualPanel::CreateLabel(string name, int x, int y, string text, color clr, int size)
{
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
}

//+------------------------------------------------------------------+
//| Create rectangle on chart                                        |
//+------------------------------------------------------------------+
void CVisualPanel::CreateRectangle(string name, int x1, int y1, int x2, int y2, color clr)
{
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x1);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y1);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, x2 - x1);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, y2 - y1);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
//| Get heatmap color based on value                                 |
//+------------------------------------------------------------------+
color CVisualPanel::GetHeatmapColor(double value, bool isZScore)
{
   if(isZScore)
   {
      // Z-score color mapping: negative (blue) to positive (red)
      // Strong negative = strong blue, strong positive = strong red
      if(value > 2.0)
         return clrDarkRed;
      else if(value > 1.0)
         return clrRed;
      else if(value > 0.5)
         return clrOrangeRed;
      else if(value > -0.5)
         return clrLightGray;
      else if(value > -1.0)
         return clrLightBlue;
      else if(value > -2.0)
         return clrBlue;
      else
         return clrDarkBlue;
   }
   else
   {
      // Correlation color mapping: -1 (red) to +1 (green)
      if(value > 0.8)
         return clrDarkGreen;
      else if(value > 0.6)
         return clrGreen;
      else if(value > 0.4)
         return clrLightGreen;
      else if(value > 0.2)
         return clrYellowGreen;
      else if(value > -0.2)
         return clrLightGray;
      else if(value > -0.4)
         return clrLightSalmon;
      else if(value > -0.6)
         return clrSalmon;
      else if(value > -0.8)
         return clrCrimson;
      else
         return clrDarkRed;
   }
}

//+------------------------------------------------------------------+
//| Draw correlation or Z-score heatmap                              |
//+------------------------------------------------------------------+
bool CVisualPanel::DrawHeatmap(double matrix[][], string symbols[], int size, bool isZScore)
{
   if(!m_isVisible)
      return false;
   
   string title = isZScore ? "Z-Score Matrix" : "Correlation Matrix";
   
   // Draw title
   CreateLabel(GetObjectName("Title"), m_panelX, m_panelY, title, clrBlack, 10);
   
   // Draw symbol labels
   for(int i = 0; i < size; i++)
   {
      // Column headers
      int xPos = m_panelX + m_cellSize + i * m_cellSize + m_cellSize / 2;
      CreateLabel(GetObjectName("Col_" + IntegerToString(i)), 
                  xPos, m_panelY + 20, symbols[i], clrBlack, m_fontSize);
      
      // Row headers
      int yPos = m_panelY + 40 + i * m_cellSize + m_cellSize / 2;
      CreateLabel(GetObjectName("Row_" + IntegerToString(i)),
                  m_panelX, yPos, symbols[i], clrBlack, m_fontSize);
   }
   
   // Draw heatmap cells
   for(int i = 0; i < size; i++)
   {
      for(int j = 0; j < size; j++)
      {
         int x1 = m_panelX + m_cellSize + j * m_cellSize;
         int y1 = m_panelY + 40 + i * m_cellSize;
         int x2 = x1 + m_cellSize;
         int y2 = y1 + m_cellSize;
         
         double value = matrix[i][j];
         color cellColor = GetHeatmapColor(value, isZScore);
         
         string rectName = GetObjectName("Cell_" + IntegerToString(i) + "_" + IntegerToString(j));
         CreateRectangle(rectName, x1, y1, x2, y2, cellColor);
         
         // Add value text
         string valueTxt = DoubleToString(value, 2);
         string txtName = GetObjectName("Val_" + IntegerToString(i) + "_" + IntegerToString(j));
         CreateLabel(txtName, x1 + 5, y1 + m_cellSize / 2, valueTxt, clrWhite, m_fontSize - 1);
      }
   }
   
   ChartRedraw();
   return true;
}

//+------------------------------------------------------------------+
//| Draw information panel                                           |
//+------------------------------------------------------------------+
bool CVisualPanel::DrawInfoPanel(string info)
{
   if(!m_isVisible)
      return false;
   
   CreateLabel(GetObjectName("InfoPanel"), m_panelX, m_panelY + 400, info, clrBlue, 9);
   ChartRedraw();
   return true;
}

//+------------------------------------------------------------------+
//| Update information panel with current statistics                 |
//+------------------------------------------------------------------+
bool CVisualPanel::UpdateInfoPanel(string regimeInfo, double avgCorr, int activeTrades)
{
   if(!m_isVisible)
      return false;
   
   int yOffset = 400;
   
   CreateLabel(GetObjectName("Info_Regime"), m_panelX, m_panelY + yOffset,
               "Market Regime: " + regimeInfo, clrBlue, 9);
   
   CreateLabel(GetObjectName("Info_AvgCorr"), m_panelX, m_panelY + yOffset + 20,
               "Avg Correlation: " + DoubleToString(avgCorr, 3), clrBlue, 9);
   
   CreateLabel(GetObjectName("Info_Trades"), m_panelX, m_panelY + yOffset + 40,
               "Active Pairs: " + IntegerToString(activeTrades), clrBlue, 9);
   
   CreateLabel(GetObjectName("Info_Time"), m_panelX, m_panelY + yOffset + 60,
               "Last Update: " + TimeToString(TimeCurrent(), TIME_SECONDS), clrGray, 8);
   
   ChartRedraw();
   return true;
}

//+------------------------------------------------------------------+
//| Show panel                                                        |
//+------------------------------------------------------------------+
void CVisualPanel::Show()
{
   m_isVisible = true;
}

//+------------------------------------------------------------------+
//| Hide panel                                                        |
//+------------------------------------------------------------------+
void CVisualPanel::Hide()
{
   m_isVisible = false;
   Clear();
}

//+------------------------------------------------------------------+
//| Clear all panel objects                                          |
//+------------------------------------------------------------------+
void CVisualPanel::Clear()
{
   // Remove all objects with our prefix
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, m_chartPrefix) == 0)
         ObjectDelete(0, name);
   }
   
   ChartRedraw();
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                    MSocketEA.mq5 |
//|                                                             Joey |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Joey"
#property link      "https://www.mql5.com"
#property version   "1.00"

//--- Importing Socket Header File for handling
#include <C:\Users\HP\Downloads\socket-library-mt4-mt5.mqh>
#include <Trade/Trade.mqh>
#include <Trade\OrderInfo.mqh> //Instatiate Library for Orders Information
#include <Trade\PositionInfo.mqh> //Instatiate Library for Positions Information
#include <Trade\SymbolInfo.mqh>
CTrade trade;
CPositionInfo pInfo;
COrderInfo orderInfo;
CSymbolInfo symbol_info;

//--- input parameters

input string Hostname = "DESKTOP-M6KUT1R";
input ushort ServerPort = 9999;
input float profitCount = 60;
input double profit = 2;
input double safeProfit = 2;
input double ratio = 10;
input int _limit = 10;
input double lot = 0.01;
input double stopLoss = 15;
input int shift = 10;
input double lspread = 50;
input double volatility = 200;

ClientSocket * glbClientSocket = NULL;//---Global Socket Delcaration
bool scon = false;//---Is Socket Connected bool
bool received = false;//---To check if Data has been received from Server
bool lever = false;//--- To toggle the socket to allows Reliable receiving of data from Server
int key = 0;//---To send Open High and Close values sequentially to server
double prediction = 0;//---Predicted Close
bool stop = false; //---Used to stop bot when target is reached
double startBalance =AccountInfoDouble(ACCOUNT_BALANCE);//-- The initial balance of the account
int magic = 0;


//+------------------------------------------------------------------+
//|     Function to Open a Trade                                     |
//+------------------------------------------------------------------+
void closeAllTrades(ClientSocket * socket)
  {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);;
   int limit = PositionsTotal();

   for(int i = PositionsTotal() - 1; i >= 0; i--) // loop all Open Positions
      if(pInfo.SelectByIndex(i))  // select a position
         //
         if(pInfo.Profit()>profit)
           {
            trade.PositionClose(pInfo.Ticket());
           }
      //if profit on trade is reached
   if(pInfo.Profit()<profit*-ratio)
     {
      trade.PositionClose(pInfo.Ticket());
     }
     //if equity falls too low
   if(equity < (balance-stopLoss))
     {
      trade.PositionClose(pInfo.Ticket());
     }
     //If equity is greater than balance plus profit
   if(equity>balance + profit)
     {
      trade.PositionClose(pInfo.Ticket());
     }
     // If equity is greater than balance, close losing trades
     //if(pInfo.Profit()<-1 && equity > balance){
     //trade.PositionClose(pInfo.Ticket());
     //}
     //if taget profit is reached
   if(equity>startBalance+profitCount)
     {
      trade.PositionClose(pInfo.Ticket());
      stop = true;
     }

  }

//+------------------------------------------------------------------+
//|          Function to Calculate Optimal Position                  |
//+------------------------------------------------------------------+
void calculatePositon(double predicted,int b_s)
  {
  
  //Checking for number of trades
   int limit = PositionsTotal();
   if(limit >_limit - 1)
     {
      return;
     }
   
   //Checking for spread
   double spread = symbol_info.Spread();
   if(spread>lspread){
   return;
   }
   
   //Checking for volatility
    double _high = iHigh(Symbol(),PERIOD_CURRENT,shift);
   double _low = iLow(Symbol(),PERIOD_CURRENT,shift);
   double diff = _high-_low;
   if(diff>volatility){
   return;
   }

//---To Calculate the Estimated Profit of a Trade
//First take the current Ask Price of the Market
   double ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
//Then take the current Bid Price of the Market(the value on the Y-axis)
   double bid = NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_BID),_Digits);
//Next take the future Bid Price of the market
   double difference =(predicted>bid)?(predicted - bid):(bid - predicted);
   PlotIndexGetInteger(0,PLOT_ARROW,0);

   if(b_s == 0)
     {
      trade.Buy(lot,Symbol(),bid,NULL,NULL);
      limit++;
     }
   else
     {
      trade.Sell(lot,Symbol(),ask,NULL,NULL);
      limit++;

     }

//Find the difference between the bid prices and multiply by the Ask Price of the Market

  }


//+------------------------------------------------------------------+
//|       Function to Create Arrow Indicator                         |
//+------------------------------------------------------------------+
void createArrow(int x)
  {

   MqlRates PriceInformation[];
   ArraySetAsSeries(PriceInformation,true);
   CopyRates(Symbol(),PERIOD_CURRENT,0,Bars(Symbol(),Period()),PriceInformation);

   if(x==0)
     {
      ObjectCreate(0,"Buy",OBJ_ARROW_BUY,0,TimeCurrent(),(PriceInformation[0].tick_volume));
      ObjectSetInteger(0,"Buy",OBJPROP_COLOR,clrGreen);
     }
   else
      if(x==1)
        {
         ObjectCreate(0,"Buy",OBJ_ARROW_SELL,0,TimeCurrent(),(PriceInformation[0].high));
         ObjectSetInteger(0,"Buy",OBJPROP_COLOR,clrRed);
        }
      else
         if(x==2)
           {
            ObjectCreate(0,"Buy",OBJ_ARROW_STOP,0,TimeCurrent(),(PriceInformation[0].high));
           }


   ObjectSetInteger(0,"Buy",OBJPROP_ARROWCODE,1);

   ObjectSetInteger(0,"Buy",OBJPROP_WIDTH,13);//---
   ObjectMove(0,"Buy",0,TimeCurrent(),PriceInformation[0].high);
  }



//+------------------------------------------------------------------+
//|       Function to Delete Arrow Indicator                         |
//+------------------------------------------------------------------+
void deleteArrow()
  {
   ObjectDelete(0,"Buy");
  }

//+------------------------------------------------------------------+
//|            Function to Send Open,High,Low for Prediction         |

//+------------------------------------------------------------------+
void sendValuesToServer(ClientSocket * socket)
  {

   double _open =iOpen(Symbol(),PERIOD_CURRENT,shift);
   double _high = iHigh(Symbol(),PERIOD_CURRENT,shift);
   double _low = iLow(Symbol(),PERIOD_CURRENT,shift);
   double _close = iClose(Symbol(),PERIOD_CURRENT,shift);
   long _vol = iVolume(Symbol(),PERIOD_CURRENT,shift);
   
   double _prevClose = iClose(Symbol(),PERIOD_CURRENT,(shift+1));
   double _prevOpen = iOpen(Symbol(),PERIOD_CURRENT,(shift+1));
   int type = (_prevOpen>=_prevClose)?1:0;
   
//---First Check if there is any change in Open Price
//---If not check if there is a change in High
//---Then CHeck if there is a change in low

//---First Send Open
   if(key ==0)
     {
      socket.Send(_open);
      key++;
     }
   else
      if(key==1)
        {
         socket.Send(_high);
         key++;
        }
      else
         if(key ==2)
           {
            socket.Send(_low);
            key++;
           }
         else
            if(key ==3)
              {
               socket.Send(_vol);
               key++;
              }
              else
            if(key ==4)
              {
               socket.Send(type);
               key = 0;
              }

  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   deleteArrow();
//--- destroy timer
   EventKillTimer();
   if(glbClientSocket)
     {
      delete glbClientSocket;
      glbClientSocket = NULL;
     }

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
int counter = 0;
void OnTick()
  {
   closeAllTrades(glbClientSocket);
   if(stop)
     {
      return;
     }

//---First lets try and create the Socket
   if(!glbClientSocket)
     {
      glbClientSocket = new ClientSocket(Hostname, ServerPort);
      if(glbClientSocket.IsSocketConnected())
        {
         scon = true;
         Print("Is connected");
        }
      else
        {
         scon = false;
         Print("Socket Connection Failed");
        }
     }
   if(scon && !stop)
     {

      // Send the current price as a CRLF-terminated message
      double _open =iOpen(Symbol(),PERIOD_CURRENT,0);
      double _high = iHigh(Symbol(),PERIOD_CURRENT,0);
      double _low = iLow(Symbol(),PERIOD_CURRENT,0);
      double _current = SymbolInfoDouble(Symbol(),SYMBOL_BID);
      int b_s = 0;

      sendValuesToServer(glbClientSocket);
      string msg = "";
      if(key == 0)
        {
         msg = glbClientSocket.Receive("");
         Print("Received:",msg);
        }



      if(StringToDouble(msg)!=0)
        {
         prediction = StringToDouble(msg);
         //---Print("CP:",prediction);

         //---If Current Price is More than Prediction Indicate "Buy" the Market
         if((prediction-(_current+(safeProfit+profit)*_Point))>0)
           {
           b_s = 0;
            deleteArrow();
            createArrow(0);
           }
         //---Else if Current Price is Less than the PredictionIndicate "Sell" the Market
         else
            if((prediction-(_current-(safeProfit+profit)*_Point))<0)
              {
              b_s = 1;
               deleteArrow();
               createArrow(1);
              }
            else
              {
               deleteArrow();
               createArrow(2);
               
              }
              calculatePositon(prediction,b_s);
        }



      if(true)
        {
         //---Print(prediction,"***Taken");
         delete glbClientSocket;
         glbClientSocket = NULL;
         lever = false;

        }
      else
        {
         lever = true;
        }


     }


  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---

  }
//+------------------------------------------------------------------+


//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---

  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---

  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---

  }
//+------------------------------------------------------------------+

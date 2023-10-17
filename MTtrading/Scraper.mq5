//+------------------------------------------------------------------+
//|                                                      Scraper.mq5 |
//|                                                             Joey |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Joey"
#property link      "https://www.mql5.com"
#property version   "1.00"

//--- Importing Socket Header File for handling
#include <C:\Users\HP\Downloads\socket-library-mt4-mt5.mqh>


input string Hostname = "DESKTOP-M6KUT1R";
input ushort ServerPort = 5555;


ClientSocket * glbClientSocket = NULL;//---Global Socket Delcaration
bool scon = false;//---Is Socket Connected bool
bool received = false;//---To check if Data has been received from Server
int key = 0;//---To send Open High Low and Close values sequentially to server

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void receiveInput()
  {
   double _ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double _bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);

   double _open =iOpen(Symbol(),PERIOD_CURRENT,0);
   double _high = iHigh(Symbol(),PERIOD_CURRENT,0);
   double _low = iLow(Symbol(),PERIOD_CURRENT,0);
   double _close = iClose(Symbol(),PERIOD_CURRENT,0);
   long _vol = iVolume(Symbol(),PERIOD_CURRENT,0);


  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendValuesToServer(ClientSocket * socket)
  {

   double _open =iOpen(Symbol(),PERIOD_CURRENT,0);
   double _high = iHigh(Symbol(),PERIOD_CURRENT,0);
   double _low = iLow(Symbol(),PERIOD_CURRENT,0);
   double _close = iClose(Symbol(),PERIOD_CURRENT,0);
   long _vol = iVolume(Symbol(),PERIOD_CURRENT,0);
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
         if(key == 3){
         socket.Send(_close);
         key++;
         }
      else
         if(key == 4){
         socket.Send(_vol);
         key = 0;
         }
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---Check if the socket is connected
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
   sendValuesToServer(glbClientSocket);
   
         delete glbClientSocket;
         glbClientSocket = NULL;


     
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

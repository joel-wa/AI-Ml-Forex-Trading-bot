#This Machine EA Server is used to receive values from a client and send its analysis back to it in realtime
#Working Process:
# First it receives Open High Low Volume (OHLV) values from the client
#It then stores the previous set of OHLV values and compares the previous O to the current O
#If the current O is greater than the previous O then the previous O was Bullish
#This Information is written to the machine and is used for its estimation
#This is the equivalent of using the open and closes to determine Bullish or Bearish candles

#Observation:
#Since the machine can be at times late to make perfect Buys or Sells, the client would send
#shifted candle sticks to it to allow for overhead analysis.
#This process should lead to better timing for increased profits


import socket
import pandas as pd
import joblib
import os.path
from sklearn.linear_model import LinearRegression


#Corrupts at index 845


modelLocation = r'C:/Users/HP/PythonMachine/3pEURUSDModel23'




s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
serverName = 'MEAServer'
s.bind((socket.gethostname(),9999))
s.listen(10)
dir = r"C:/Users/HP/PythonMachine/"


def previousCandle(_open,_close):
    print(f'close is {_close}')
    if(_open>_close):
        return 1 #Bearish
    else:
        return 0 #Bullish

def decoder(socket):
    data = socket.recv(1024)
    input_value = float(data.decode("utf-8"))
    return input_value


def create_DataFrame(a,b,c,d,e):
    dfx = pd.DataFrame(data = {'Open':[a],'High':[b],'Low':[c],
    'Volume':[d],
    'PreviousType':[e],
    })
    #storeHistory(c,b,a,0,t)
    #t+=1
    
    return dfx

def predictClose(value):
    model = LinearRegression()
    model = joblib.load(modelLocation)
    output_value = model.predict(value)
    return output_value


storeKey = 0
startKey = 0

storeArray = []
previousArray = [0,0,0,0]

while True:
    print('Starting')
    client_socket, address = s.accept()
    print(f"Connection from {address}")
    storeArray.append(decoder(client_socket))
    storeKey+=1
    print(storeArray)   
    if(storeKey >= 5):
        # Open  High    Low     Volume   PreviousClose   Previous Candle Type     
        dfx = create_DataFrame(storeArray[0],storeArray[1],storeArray[2],storeArray[3],storeArray[4])
        print('storeArray is: ',storeArray)
        storeKey =0
        print(dfx)
        try:
            prediction = predictClose(dfx)
            client_socket.send(bytes(f"{prediction[0]}","utf-8"))  
            previousArray = storeArray
        except:
            client_socket.send(bytes(f"Error","utf-8"))
            previousArray = [0,0,0,0]
        storeArray.clear()
 
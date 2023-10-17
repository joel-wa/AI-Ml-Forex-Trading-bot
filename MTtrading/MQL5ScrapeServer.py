#Scrape Server to Store incoming values to CVS for later training
import socket
import pandas as pd
import csv
import os
import os.path


_open = 0
_high = 0
_low = 0
_close = 0
_volume = 0

#Corrupts at index 845


s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
serverName = 'ScrapeServer'
fileName = "4EURUSD_MQLScrape.csv"
s.bind((socket.gethostname(),5555))
s.listen(10)
dir = r"C:/Users/HP/PythonMachine/"


def previousCandle(_open,_close):
    if(_open>_close):
        return 1 #Bearish
    else:
        return 0 #Bullish

def decoder(socket):
    data = socket.recv(1024)
    input_value = (data.decode("utf-8"))
    return input_value

def store(argument,storeKey):
    match storeKey:
        case 0:
            _open = argument
            return _open
        case 1:
            _high = argument
            return _high
        case 2:
            _low = argument
            return _low
        case 3:
            _close = argument
            return _close
        case 4:
            _volume = argument
            return _volume

def initiateFile(key):
    if (key == 0):
        with open(os.path.join(dir,fileName), 'a', newline = '') as file:
            _gwriter = csv.writer(file)
            _gwriter.writerow(['Open','High','Low','Close','Volume','PreviousType'])
    else:
         return

def writeToFile(_open,_high,_low,_close,_volume,_type):
    with open(os.path.join(dir,fileName), 'a', newline = '') as file:
        _gwriter = csv.writer(file)
        _gwriter.writerow([_open,_high,_low,_close,_volume,_type])
    return


storeKey = 0
startKey = 0

storeArray = []
previousArray = [0,0,0,0]

while True:
    initiateFile(startKey)
    startKey +=1
    print('Starting')
    client_socket, address = s.accept()
    print(f"Connection from {address}")
    storeArray.append(store(decoder(client_socket),storeKey))
    storeKey+=1
    print(storeArray)   
    if(storeKey >= 5):
        writeToFile(storeArray[0],storeArray[1],storeArray[2],storeArray[3],storeArray[4],previousCandle(previousArray[0],previousArray[3]))
        storeKey =0
        previousArray = storeArray
        storeArray.clear()

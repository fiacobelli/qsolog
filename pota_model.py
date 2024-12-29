import external_strings as s
import urllib.parse
import urllib.request
import urllib.response
import utils as u
import ssl
import json
import ast
from PyQt6 import QtCore, QtGui, QtWidgets, uic
from PyQt6.QtCore import Qt

class PotaModel:

    def __init__(self):
        self.jsonObj = ""
        self.col_names = []
        self.rows = []
        
    '''
    Takes a json list of json objects
    and populates the PotaModel object.
    '''
    def json2table(self,json_str: str,ignore = ["SPOTTER","SOURCE","SPOTID","SPOTTIME","NAME"]):
        #json_str = json_str.replace("'",'"')
        #print(json_str[:10],type(json_str))
        # find how to parse json with single quotes on the properties.
        self.jsonObj = json.loads(json.dumps(eval(str(json_str))))
        # I'll take the keys from the first Json element.
        row1 = self.jsonObj[0]
        self.col_names =list(row1.keys())
        self.col_names = [x for x in self.col_names if x.upper() not in ignore] # update without ignore
        for r in self.jsonObj:
            self.rows.append([r[x] for x in self.col_names])
        #print(self.col_names,self.rows[:10])
        return (self.rows, self.col_names)


    def retrieve_spots(self):
        resp = urllib.request.urlopen("https://api.pota.app/spot/")
        return resp.read()
    
class PotaTableModel(QtCore.QAbstractTableModel):
        # Qt Model methods
    def __init__(self,data,cols):
        super(PotaTableModel,self).__init__()
        self._data = data
        self.columns = cols


    def get_cols(self):
        colst =[str(x).capitalize() for x in self.columns]
        return colst


    def flags(self, index):
        return Qt.ItemFlag.ItemIsSelectable|Qt.ItemFlag.ItemIsEnabled


    def rowCount(self, index):
        return len(self._data)


    def columnCount(self, index):
        return len(self.columns) 
    

    def headerData(self,section,orientation,role):
        if role == Qt.ItemDataRole.DisplayRole:
            if orientation == Qt.Orientation.Horizontal:
                return self.columns[section]
        elif role == Qt.ItemDataRole.FontRole:
            f = QtGui.QFont("Helveica",10)
            f.setBold(True)
            return f
        elif role == Qt.ItemDataRole.BackgroundRole:
            return QtGui.QBrush(Qt.BrushStyle.Dense4Pattern) #QtGui.QColor('#053061')


    def data(self, index, role):
        i = index.row()
        j = index.column()
        colname = self.columns[j].upper()
        if role == Qt.ItemDataRole.DisplayRole:
            return self._data[i][j]
        elif role == Qt.ItemDataRole.BackgroundRole and colname == s.MODE:
            if self._data[i][j] == "CW":
                return QtGui.QColor('blue')
            elif self._data[i][j] == "SSB":
                return QtGui.QColor("green")
            else:
                return QtGui.QColor("red")


    def format_band_color(self,value):
        value = value.strip()
        if (value[:-1].isnumeric()):
            num = int(value[:-1])%148
            color = QtGui.QColor.colorNames()[num]
            return QtGui.QColor(color)
        else:
            return QtGui.QColor('black')
   


if __name__=="__main__":
    pm = PotaModel()
    # js = open('testpota.json','r',encoding="utf-8").read() 
    js = pm.retrieve_spots()
    data,cols = pm.json2table(js)
    print(cols,len(data))
    print(pm.rows[10])




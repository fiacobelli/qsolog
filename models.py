import utils
import os
import json
import pickle
import datetime
import time
import external_strings as s
import sys
from PyQt6 import QtCore, QtGui, QtWidgets, uic
from PyQt6.QtCore import Qt
import sqlite3

QSO_DB = "qso.db"
class Contact:
    def __init__(self, cid,my_callsign,their_callsign,date,time,band,mode,comment=None,sat_name=None,sat_mode=None):
        self.id = cid
        self.my_callsign = my_callsign
        self.call = their_callsign
        self.qso_date = date
        self.qso_time = time #datetime object.
        self.band = band
        self.mode = mode
        self.sat_name = sat_name # Satellite
        self.sat_mode = sat_mode # propagation mode for satellites.
        self.comment = comment
        self.other = {}
        self.must_have_keys = [s.QSO_ID,s.MY_CALLSIGN,s.CALL,s.QSO_DATE,s.TIME_ON,s.BAND,s.MODE,s.SAT_MODE,s.SAT_NAME,s.COMMENT]
        #print(self.qso_date,type(self.qso_date),self.qso_time, type(self.qso_time))

    
    def is_emplty(self):
        return len(self.call)<1

    def __eq__(self, __o: object) -> bool:
        if not isinstance(__o,Contact):
            return False
        else:
            return __o.id == self.id
    

    def matches(self, contact):
        if type(self.qso_date) is not type(contact.qso_date):
            print("Bad contact:",self.__dict__)
            return False
        dt = datetime.datetime.combine(self.qso_date,self.qso_time)
        dt2 = datetime.datetime.combine(contact.qso_date,contact.qso_time)
        return self.my_callsign == contact.call and \
               self.call == contact.my_callsign and \
               utils.within_thirty_minutes(dt,dt2) and \
               self.band == contact.band and \
               self.mode == contact.mode and \
               self.sat_name == contact.sat and \
               self.sat_mode == contact.sat_mode
    

    def add_field(self,field,value):
        self.other[field]=value


    def as_dict(self):
        d = self.__dict__
        for k in d['other']:
            d[k] = d['other'][k]
        return d
    
    def get_attr(self,name):
        d = self.as_dict()
        print("ATRIBG: Getting",name,name in d)
        if name in d:
            return d[name]
        else:
            return ""
        
        
    @classmethod
    def from_dictionarystr(cls,dictstr):
        # Just a dictionary with the right fields. Dates and times must be date and time objects.
        # Normalize the dictionary. It must have:
        
        for k in s.MUST_HAVE_QSO_FIELDS:
            if k not in dictstr:
                dictstr[k]="" # Default to empty.
            elif k == s.QSO_DATE:
                dictstr[k] = datetime.datetime.strptime(str(dictstr[k]).strip(),r"%Y%m%d").date()
            elif k == s.TIME_ON:
                dictstr[k] = datetime.datetime.strptime(str(dictstr[k]).strip(),r'%H%M%S').time()
                    
        c = cls(dictstr.pop(s.QSO_ID), dictstr.pop(s.MY_CALLSIGN), dictstr.pop(s.CALL), 
                dictstr.pop(s.QSO_DATE),dictstr.pop(s.TIME_ON), dictstr.pop(s.BAND), 
                dictstr.pop(s.MODE), sat_name = dictstr.pop(s.SAT_NAME), sat_mode=dictstr.pop(s.SAT_MODE),comment=dictstr.pop(s.COMMENT))
        for k in dictstr: # The remaining fields must be checked for correct datatypes.
            if k.startswith(s.FREQ):
                dictstr[k] = float(str(dictstr[k]))
        c.other = dictstr
        if c.qso_date==None or c.qso_time==None or c.call == None or c.band == None or c.qso_date=="" or c.qso_time=="" or c.call == "" or c.band == "":
            return None
        return c

    def update_contact(self,**kwargs):
        self.my_callsign = kwargs[s.MY_CALLSIGN]
        self.call = kwargs[s.CALL]
        self.qso_date = kwargs[s.QSO_DATE]
        self.qso_time = kwargs[s.TIME_ON]
        self.band = kwargs[s.BAND]
        self.mode = kwargs[s.MODE]
        self.sat_name = kwargs[s.SAT_NAME] # Satellite
        self.sat_mode = kwargs[s.SAT_MODE] # propagation mode for satellites.
        self.comment = kwargs[s.COMMENT]
        for k,v in kwargs.items():
            if k not in self.must_have_keys:
                self.other[k]=v
        self.update_contact()
        return True
            

    def update_db(self):
    # Connect to the SQLite3 database
        conn = sqlite3.connect(QSO_DB)
        cursor = conn.cursor()

        # Update the row in the table
        update_query = """
                        UPDATE qso
                        SET my_callsign = ?,
                            call = ?,
                            qso_date = ?,
                            time_on = ?,
                            band = ?,
                            mode = ?,
                            sat_mode = ?,
                            sat_name = ?,
                            comment = ?,
                            other = ?
                        WHERE qso_id = ?
                        """

    # Execute the update query
        cursor.execute(update_query, (
            self.my_callsign, self.call,int(self.qso_date.timestamp()),self.time_on,self.band,
            self.mode,self.sat_mode, self.other, self.id
        ))

        # Commit the changes and close the connection
        conn.commit()
        conn.close()
        return True
    




class LogBook:
    def __init__(self,name="",path=""):
        self.name = name
        self.path = path #full path
        self.last_id = 0
        self.contacts = {} #callsign:[contacts]
        self.contacts_by_id=[]
        
    def contact_exists(self,contact):
        for c in self.contacts_by_id:
            #print(c.call,contact.call,c.matches(contact))
            if c.matches(contact):
                #print("Contact\n",contact.__dict__,"\nIn the Logbook Already")
                return True
        return False
    
    def add_contact(self,contact):
        # Is this contact an existing one?
        if self.contact_exists(contact):
            print("Contact already in the logbook",contact.call)
            return None
        print("Contact Added",contact.call)
        if contact.call in self.contacts:
            self.contacts[contact.call].append(contact)
        else:
            self.contacts[contact.call] = [contact]
        self.contacts_by_id.append(contact)

    def remove_contact(self,contact):
        self.contacts[contact.call].remove(contact)
        return self.contacts_by_id.remove(contact)

    def update_contact(self, contact,**kwargs):
        idx = self.find_contact_index(self.contacts_by_id,contact)
        if idx:
            c = self.contacts_by_id[idx]
            c.update(**kwargs)
            return True
        return False
    
    def find_contact_index(clist,contact):
        idx = 0
        while contact.cid != clist[idx].cid:
            idx+=1
        if idx<len(clist):
            return idx
        return None

    def get_contact_by_id(self,cid):
        idx = 0
        print("Getting contact ID",cid)
        for c in self.contacts_by_id:
            if c.id == cid:
                return c
        return None

    def get_next_id(self):
        self.last_id +=1
        return self.last_id - 1

    def save_logbook(self):
        with open(self.path,"wb") as file:
            pickle.dump(self,file)

    @classmethod
    def load_logbook(self,path):
        if os.path.exists(path):
            with open(path,"rb") as file:
                return pickle.load(file)
        else:
            return self("new log",path)



class LogBookTableModel(QtCore.QAbstractTableModel):
        # Qt Model methods
    def __init__(self,logbook):
        super(LogBookTableModel,self).__init__()
        self.logbook = logbook
        self.col_list = self.get_cols('columns.config')
        print(self.rowCount(0))

    def get_cols(self,fname):
        l = open(fname,'r').read().strip().split("\n")
        colst =[x.split(",")[1] for x in l]
        return colst

    def flags(self, index):
        return Qt.ItemFlag.ItemIsSelectable|Qt.ItemFlag.ItemIsEnabled
    
    def update(self, dataIn):
        print('Updating Model')
        print(dataIn)
        print (f'Datatable : {0}')

    def rowCount(self, index):
        return len(self.logbook.contacts_by_id)

    def columnCount(self, index):
        cols=0
        if len(self.logbook.contacts_by_id)>0:
            cols = len(self.col_list)+1
            cont = self.logbook.contacts_by_id[0]
            self.columns = ['id']+self.col_list #[k for k in cont.as_dict()]
            self.headers = [k.replace("_"," ").title() for k in self.columns]
        return cols # add one for the distance.
    
    def headerData(self,section,orientation,role):
        if role == Qt.ItemDataRole.DisplayRole:
            if orientation == Qt.Orientation.Horizontal:
                return self.headers[section]
        elif role == Qt.ItemDataRole.FontRole:
            f = QtGui.QFont("Helveica",10)
            f.setBold(True)
            return f
        elif role == Qt.ItemDataRole.BackgroundRole:
            return QtGui.QBrush(Qt.BrushStyle.Dense4Pattern) #QtGui.QColor('#053061')

    def data(self, index, role):
        i = self.rowCount(None)-1-index.row()
        j = index.column()
        colname = self.columns[j].upper()
        if role == Qt.ItemDataRole.DisplayRole:
            return self.format_data(i,j)
        elif role == Qt.ItemDataRole.BackgroundRole and colname == s.MY_CALLSIGN:
            return QtGui.QColor('blue')
        elif role == Qt.ItemDataRole.ForegroundRole and colname == s.BAND:
            value = self.logbook.contacts_by_id[i].as_dict()[colname.lower()]
            return self.format_band_color(value)
        elif role == Qt.ItemDataRole.DecorationRole and colname == s.CALL:
            return self.format_flag(self.logbook.contacts_by_id[i])
        elif role == Qt.ItemDataRole.DecorationRole and colname == s.BAND:
            value = self.logbook.contacts_by_id[i].as_dict()[colname.lower()]
            return self.format_band_color(value)

        
    def format_data(self,i,j):
        ctct = self.logbook.contacts_by_id[i].as_dict()
        field = self.columns[j]
        value = ctct[field] if field in ctct else None
       # print(field,value,ctct)
        retval = value
        if isinstance(value,datetime.date) and (self.columns[j]).upper()==s.QSO_DATE:
            retval = value.strftime(r'%Y-%m-%d')
        elif isinstance(value,datetime.time):
            retval = value.strftime(r'%H:%M UTC')
        elif isinstance(value,float):
            retval = "%.6f" % value
        else:
            retval = str(value)
        return retval

    def format_band_color(self,value):
        value = value.strip()
        if (value[:-1].isnumeric()):
            num = int(value[:-1])%148
            color = QtGui.QColor.colorNames()[num]
            return QtGui.QColor(color)
        else:
            return QtGui.QColor('black')
        
    def format_flag(self,contact):
        if s.COUNTRY in contact.other:
            country = contact.other[s.COUNTRY]
            if country in s.countries:
                return QtGui.QIcon("flags/"+s.countries[country].lower()+".png")


class Translator:
    def __init__(self):
        self.supported_formats=['adi']


    def adi_element(self,key,value,eol="\n"):
        if value is None or len(str(value))<1:
            return ""
        else:
            return f"<{key.lower()}:{len(str(value))}>{str(value)} {eol}"


    def contact2adi(self,contact):
            adi = self.adi_element(s.OPERATOR,contact.my_callsign)
            adi += self.adi_element(s.QSO_DATE,contact.qso_date.strftime(r'%Y%m%d'))+"\n"
            adi += self.adi_element(s.TIME_ON,contact.qso_time.strftime(r'%H%M'))+"\n"
            adi += self.adi_element(s.BAND,contact.band)
            adi += self.adi_element(s.MODE,contact.mode)
            adi += self.adi_element(s.SAT_NAME,contact.sat_name)
            adi += self.adi_element(s.CALL,contact.call)
            adi += self.adi_element(s.SAT_MODE,contact.sat_mode)
            adi += self.adi_element(s.COMMENT,contact.comment)
            for key in contact.other:
                adi += self.adi_element(key,contact.other[key])
            # Some housekeeping:
            adi += self.adi_element(s.CONTACTED_OP,contact.call)
            adi += self.adi_element(s.STATION_CALLSIGN,contact.my_callsign)

            adi += f"<{s.EOR.lower()}>\n"
            return adi
            
    def logbook2adi(self,logbook):
        adi = f"Generated on {datetime.datetime.today().strftime(r'%Y-%m-%d')} for {logbook.name} \n"
        adi += self.adi_element(s.ADIF_VER.lower(),"3.0.5")
        adi += self.adi_element(s.PROGRAMID.lower(),"QsoLog")
        adi += self.adi_element(s.PROGRAMVERSION.lower(),"1.0")
        adi += f"<{s.EOH}>\n"
        for c in logbook.contacts_by_id:
            if not c.is_emplty():
                adi += self.contact2adi(c)
        return adi

    def adi2logbook(self,logbook,adi):
        header,elements = adi.split("<eoh>") if '<eoh>' in adi else adi.split("<EOH>")
        contacts = elements.split("<eor>") if '<eor>' in elements else elements.split("<EOR>")
        i = 0
        for qso in contacts:
            cont_dict = {}
            fields = qso.split("<")
            for el in fields[1:]:
                tag,rest = el.split(":",1)
                value = rest[rest.find(">")+1:]
                tag = tag.upper()
                cont_dict[tag]=value
            cont_dict[s.QSO_ID] = logbook.get_next_id()
            print("importing contact",i,cont_dict)
            c = Contact.from_dictionarystr(cont_dict)
            if c!=None:
                logbook.add_contact(c)
            i+=1
        return logbook,i
    
    def get_cabrillo_mode(self,mode):
        if mode[-2:]=='SB':
            return "PH"
        if mode == 'RTTY':
            return "RY"
        if mode != 'CW' and mode != 'FM':
            return "DG"
        return mode


    def contact2cabrillo(self,contact,tx_fields=[s.STX],rx_fields=[s.SRX]):
        freq = contact.other[s.FREQ]
        mode = self.get_cabrillo_mode(contact.mode)
        date = contact.qso_date.strftime(r'%Y-%m-%d')
        time = contact.qso_time.strftime(r'%H%M')
        call = contact.my_callsign
        rst = contact.other[s.RST_SENT]
        exchng_s = [contact.other[key] for key in tx_fields].join(" ")
        their_call = contact.their_callsign
        rstr = contact.other[s.RST_RCVD]
        exchng_r = [contact.other[key] for key in rx_fields].join(" ")
        t = "1" # This should be variable.
        return f"{s.QSO} {freq:<5} {mode} {date} {time} {call:<13} {rst:<3} {exchng_s:<6} {their_call:<13} {rstr:<3} {exchng_r:<6} {t}"








    

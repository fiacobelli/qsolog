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


class Contact:
    def __init__(self, cid,my_callsign,their_callsign,date,time,band,mode,sat_name,sat_mode, comment):
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
    
    def is_emplty(self):
        return len(self.call)<1

    def __eq__(self, __o: object) -> bool:
        if not isinstance(__o,Contact):
            return False
        else:
            return __o.id == self.id
    

    def matches(self, contact):
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


    @classmethod
    def from_dictionarystr(cls,dictstr):
        # Just a dictionary with the right fields. Dates and times must be date and time objects.
        # Normalize the dictionary. It must have:
        must_have_keys = [s.QSO_ID,s.MY_CALLSIGN,s.CALL,s.QSO_DATE,s.TIME_ON,s.BAND,s.MODE,s.SAT_MODE,s.SAT_NAME,s.COMMENT]
        for k in must_have_keys:
            if k not in dictstr:
                dictstr[k]="" # Default to empty.
        c = cls(dictstr.pop(s.QSO_ID), dictstr.pop(s.MY_CALLSIGN), dictstr.pop(s.CALL), 
                dictstr.pop(s.QSO_DATE),dictstr.pop(s.TIME_ON), dictstr.pop(s.BAND), 
                dictstr.pop(s.MODE), dictstr.pop(s.SAT_NAME), dictstr.pop(s.SAT_MODE),dictstr.pop(s.COMMENT))
        c.other = dictstr
        return c

    @classmethod
    def from_adi(cls,adi):
        return None




class LogBook:
    def __init__(self,name="",path=""):
        self.name = name
        self.path = path #full path
        self.last_id = 0
        self.contacts = {} #callsign:[contacts]
        self.contacts_by_id=[]
        
    
    def add_contact(self,contact):
        if contact.call in self.contacts:
            self.contacts[contact.call].append(contact)
        else:
            self.contacts[contact.call] = [contact]
        self.contacts_by_id.append(contact)

    def remove_contact(self,contact):
        self.contacts[contact.call].remove(contact)
        return self.contacts_by_id.remove(contact)

    def update_contact(self, contact):
        idx = self.contacts[contact.call].index(contact)
        self.contacts[contact.call][idx]=contact
    
    def get_contact_by_id(self,cid):
        idx = 0
        while cid != self.contacs_by_id[idx].cid:
            idx+=1
        if idx<len(self.contacts_by_id):
            return self.contacts_by_id[idx]
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
        cont = self.logbook.contacts_by_id[0]
        self.columns = [k for k in cont.__dict__]
        print(self.rowCount(0))

    
    def update(self, dataIn):
        print('Updating Model')
        print(dataIn)
        print (f'Datatable : {0}')

    def rowCount(self, index):
        return len(self.logbook.contacts_by_id)

    def columnCount(self, index):
        return len(self.logbook.contacts_by_id[0].__dict__) 

    def data(self, index, role):
        if role == Qt.ItemDataRole.DisplayRole:
            i = index.row()
            j = index.column()
            value = self.logbook.contacts_by_id[i].__dict__[self.columns[j]]
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


class Translator:
    def __init__(self):
        self.supported_formats=['adi']


    def adi_element(self,key,value,eol="\n"):
        if value is None or len(value)<1:
            return ""
        else:
            return f"<{key}:{len(value)}>{value} {eol}"


    def contact2adi(self,contact):
            #cid,my_callsign,their_callsign,date,time,band,mode,sat_name,sat_mode, comment
            '''  POTA_REF=self.theirParkIDLineEdit.text(),NOTES=self.theirParkNameLineEdit.text(),
                            RST_RCVD=self.RSTReceivedLineEdit.text(),RST_SENT=self.RSTSendLineEdit.text(),
                            FREQ = self.frequencyDoubleSpinBox.text(), FREQ_RX=self.frequencyTXDoubleSpinBox.text(),
                            STATE = state, LAT=lat, LON=lon,GRIDSQUARE=grid,NAME=self.qsoNameLineEdit.text(),
                            ADDRESS = self.qsoAddressLineEdit.text(), COUNTRY=self.qsoCountryLineEdit.text(),
                            CONTEST_ID = self.contestNameComboBox.text(), ARRL_SECT = self.arrlSectionLineEdit.text(),
                            QSL_RCVD = self.serialRcvLineEdit.text(), QSL_SENT=self.serialSentSpinBox.text(),
                            MY_STATE = self.myconfig[s.MY_STATE],MY_GRID=self.myconfig[s.MY_GRID],
                            MY_LAT=self.myconfig[s.MY_LAT], MY_LON=self.myconfig[s.MY_LON],
                            MY_POTA_REF = self.potaconf[s.MY_POTA_REF]'''

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

            adi += f"<{s.EOR}>\n"
            return adi
            
    def logbook2adi(self,logbook):
        adi = f"Generated on {datetime.datetime.today().strftime(r'%Y-%m-%d')} for {logbook.name} \n"
        adi += self.adi_element(s.ADIF_VER,"3.0.5")
        adi += self.adi_element(s.PROGRAMID,"QsoLog")
        adi += self.adi_element(s.PROGRAMVERSION,"1.0")
        adi += f"<{s.EOH}>\n"
        for c in logbook.contacts_by_id:
            if not c.is_emplty():
                adi += self.contact2adi(c)
        return adi.lower()

    def adi2logbook(self,logbook,adi):
        header,elements = adi.split("<eoh>") if '<eoh>' in adi else adi.split("<EOH>")
        contacts = elements.split("<eor>") if '<eor>' in elements else elements.split("<EOR>")
        i = 0
        for qso in contacts:
            print(f"Processing contact {i}")
            cont_dict = {}
            fields = qso.split("<")
            for el in fields[1:]:
                tag,rest = el.split(":",1)
                value = rest[rest.find(">")+1:]
                tag = tag.upper()
                if tag == s.QSO_DATE:
                    cont_dict[tag] = datetime.datetime.strptime(value.strip(),r"%Y%m%d").date()
                elif tag ==s.TIME_ON:
                    cont_dict[tag] = datetime.datetime.strptime(value.strip(),r'%H%M%S').time()
                else:
                    cont_dict[tag]=value
            cont_dict[s.QSO_ID] = logbook.get_next_id()
            logbook.add_contact(Contact.from_dictionarystr(cont_dict))
            i+=1
        return logbook,i
        









    

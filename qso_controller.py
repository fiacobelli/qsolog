from PyQt6.QtWidgets import *
from PyQt6.QtGui import *
import models as m
import datetime
import external_strings as s


def model_qsos_for_table(logbook):
    model = QStandardItemModel()
    model.setHorizontalHeaderLabels([k for k in logbook.contacts_by_id[0].__dict__])
    for r,cont in enumerate(logbook.contacts_by_id):
        data = [cont.__dict__[k] for k in cont.__dict__]
        for c,d in enumerate(data):
            item = QStandardItem(str(d))
            model.setItem(r,c,item)
    return model


def load_logbook(filename):
    return m.LogBook.load_logbook(filename)

def get_new_logbook(nm,filename):
    return m.LogBook(name=nm,path=filename)

def save_logbook(logbook):
    logbook.save_logbook()

def insert_contact(logbook,my_callsign,their_callsign,date,time,band,mode,sat,prop_mode_sat, comments,**kwargs):
    cid = logbook.get_next_id()
    qso = m.Contact(cid,my_callsign,their_callsign,date,time,band,mode,sat_name=sat,sat_mode=prop_mode_sat,comment=comments)
    for key,value in kwargs.items():
        qso.add_field(key,value)
    insert_qso(qso,logbook)
    

def insert_qso(contact,logbook):
    logbook.add_contact(contact)
    return True

### mapping bands to frequencies
def get_bands():
    return s.bands.keys()

def get_modes():
    return s.modes

def get_freq_for_band(band):
    return s.bands[band][0]

def get_band_for_freq(freq):
    band = ''
    for b in s.bands:
        lower,upper = s.bands(b)
        if freq>=lower and freq<=upper:
            band = b
    return band

# Searching functions
def previous_qsos_with(callsign,logbook):
    return len(logbook.contacts[callsign]) if callsign in logbook.contacts else 0

def get_matching_rows(logbook,txt):
    # This will initially just search callsigns
    idxs = [i for i,c in enumerate(logbook.contacts_by_id) if txt in c.call]
    return idxs


# QSO Configurations
def read_configurations():
    myconfig = open("qsolog.config","r").read()
    qrzconfig = open("qrz.config","r").read()
    lastconf = open("lastsettings.config","r").read()
    potaconf = open("pota.config").read()
    return(config_to_dict(myconfig),config_to_dict(qrzconfig),config_to_dict(lastconf),config_to_dict(potaconf))

def config_to_dict(config_str,delim=","):
    # Convert CSV config to DICT.
    lines = config_str.strip().split("\n")
    d = {}
    for line in lines:
        if len(line)>1:
            key,value = line.split(delim)
            d[key]=value
    return d

def save_last_state(logbookname):
    with open("lastsettings.config","w") as file:
        file.write(s.CURRENT_LOGBOOK+","+logbookname)
    return True
    

def logbook2adi(logbook,adifile):
    adistr = m.Translator().logbook2adi(logbook)
    with open(adifile,'w') as file:
        file.write(adistr)

def adifile2logbook(logbook,adifile):
    adistr = open(adifile,'r').read()
    logbook,status = m.Translator().adi2logbook(logbook,adistr)
    return logbook

if __name__=="__main__":
    logb = m.LogBook.load_logbook("test.log")
    print("Contacts",len(logb.contacts_by_id))
    #adifile2logbook(logb,"test.adi")
    #print(logb.contacts_by_id[-3:])
    logbook2adi(logb,"test2.adi")
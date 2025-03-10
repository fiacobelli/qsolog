from PyQt6.QtWidgets import *
from PyQt6.QtGui import *
import models as m
import datetime
import external_strings as s
import utils as u


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
    logbook = None
    try:
        logbook =  m.LogBook.load_logbook(filename)
        logbook.path = filename
    except:
        print("Problem Loading the logbook")
        logbook = m.LogBook("new","./temp~log.log")
    return logbook

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
    
def update_contact(contact,my_callsign,their_callsign,date,time,band,mode,sat,prop_mode_sat, comments,**kwargs):
    contact.my_callsign =  my_callsign
    contact.call = their_callsign
    contact.date = date
    contact.time = time
    contact.band = band
    contact.mode = mode
    contact.sat_name = sat
    contact.sat_mode = prop_mode_sat
    contact.comment = comments
    for key,value in kwargs.items():
        contact.add_field(key,value)
    
    

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
    idxs = [i for i,c in enumerate(logbook.contacts_by_id) if txt.upper() in c.call]
    return idxs


# QSO Configurations
def read_configurations():
    myconfig = open("qsolog.config","r").read()
    qrzconfig = open("qrz.config","r").read()
    lastconf = open("lastsettings.config","r").read()
    potaconf = open("pota.config").read()
    portableconf = open("portable.config").read()
    return(config_to_dict(myconfig),config_to_dict(qrzconfig),config_to_dict(lastconf),config_to_dict(potaconf),config_to_dict(portableconf))

def get_portable_config():
    portableconf = open("portable.config").read()
    d = config_to_dict(portableconf)
    d[s.MY_POTA_REF]=""
    return d

def get_my_config():
    myconfig = open("qsolog.config","r").read()
    d = config_to_dict(myconfig)
    d[s.MY_POTA_REF]=""
    return d

def config_to_dict(config_str,delim=","):
    # Convert CSV config to DICT.
    lines = config_str.strip().split("\n")
    d = {}
    for line in lines:
        if len(line)>1:
            key,value = line.split(delim)
            d[key]=value
    return d

def save_last_state(mainapp):
    with open("lastsettings.config","w") as file:
        file.write(s.CURRENT_LOGBOOK+","+mainapp.logbook.path+"\n")
        file.write(s.CURRENT_MODE+","+str(mainapp.specialFieldsTabWidget.currentIndex())+"\n")
        file.write(s.UI_HEIGHT+","+str(mainapp.size().height())+"\n")
        file.write(s.UI_WIDTH+","+str(mainapp.size().width()))
    return True
    

def logbook2adi(logbook,adifile):
    adistr = m.Translator().logbook2adi(logbook)
    with open(adifile,'w') as file:
        file.write(adistr)

def qsos2adistr(logbook,qso_id_list):
    qsos = [m.Translator().contact2adi(x) for x in logbook.contacts_by_id if x.id in qso_id_list]
    return "".join(qsos) 

def adifile2logbook(logbook,adifile,statusbar):
    adistr = open(adifile,'r').read()
    logbook,status = m.Translator().adi2logbook(logbook,adistr)
    statusbar.showMessage(str(status)+" contacts added.")
    return logbook

def distance_from_me(contact,lat,long,unit="km"):
    lat1 = contact.get_attr(s.LAT)
    lon1 = contact.get_attr(s.LON)
    if len(lat1)>1 and len(lon2)>1:
        return u.distance_on_earth(lat1,lon1,lat,long,unit)
    else:
        return ""
    
def distance_from_me(lat1,lon1,lat2,lon2,unit="km"):
    print(f"from {lat1}, {lon1} to {lat2}, {lon2}")
    if len(lat1)>1 and len(lon2)>1 and len(lat2)>1 and len(lon2)>1:
        return u.distance_on_earth(float(lat1),float(lon1),float(lat2),float(lon2),unit)
    else:
        return ""

if __name__=="__main__":
    #logb = m.LogBook.load_logbook("test.log")
    #print("Contacts",len(logb.contacts_by_id))
    #adifile2logbook(logb,"test.adi")
    #print(logb.contacts_by_id[-3:])
    #logbook2adi(logb,"test2.adi")
    print(distance_from_me('42.101003', '-87.894071','42.104200', '-87.708000'))
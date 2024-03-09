from PyQt6.QtWidgets import *
from PyQt6.QtGui import *
import models as m
import datetime


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

def save_logbook(logbook):
    logbook.save_logbook()

def insert_contact(logbook,my_callsign,their_callsign,date,time,band,mode,sat,prop_mode_sat, comments,**kwargs):
    cid = logbook.get_next_id()
    dtime = datetime.datetime.combine(date,time)
    qso = m.Contact(cid,my_callsign,their_callsign,dtime,band,mode,sat,prop_mode_sat,comments)
    for key,value in kwargs.items():
        qso.add_field(key,value)
    insert_qso(qso,logbook)
    

def insert_qso(contact,logbook):
    logbook.add_contact(contact)
    return True


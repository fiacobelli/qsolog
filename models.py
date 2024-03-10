import utils
import os
import json
import pickle
from datetime import datetime
import external_strings as s


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
    
    def __eq__(self, __o: object) -> bool:
        if not isinstance(__o,Contact):
            return False
        else:
            return __o.id == self.id
    

    def matches(self, contact):
        dt = datetime.combine(self.qso_date,self.qso_time)
        dt2 = datetime.combine(contact.qso_date,contact.qso_time)
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
    def from_json(cls,json_obj):
        c = cls(json_obj["cid"], json_obj["my_callsign"], json_obj[CALL], json_obj[QSO_DATE],json_obj[QSO_TIME], json_obj["band"], json_obj["mode"], json_obj["sat"], json_obj["prop_mode_sat"], json_obj[" comment"])
        c.other = json_obj["other"]
        return c




class LogBook:
    def __init__(self,name,path):
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


    







    

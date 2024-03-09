import utils
import os
import json
import pickle


class Contact:
    def __init__(self, cid,my_callsign,their_callsign,time,band,mode,sat,prop_mode_sat, comment):
        self.id = cid
        self.my_callsign = my_callsign
        self.their_callsign = their_callsign
        self.time = time #datetime object.
        self.band = band
        self.mode = mode
        self.sat = sat # Satellite
        self.prop_mode_sat = prop_mode_sat # propagation mode for satellites.
        self.comment = comment
        self.other = {}
    
    def __eq__(self, __o: object) -> bool:
        if not isinstance(__o,Contact):
            return False
        else:
            return __o.id == self.id
    

    def matches(self, contact):
        return self.my_callsign == contact.their_callsign and \
               self.their_callsign == contact.my_callsign and \
               utils.within_thirty_minutes(self.time,contact.time) and \
               self.band == contact.band and \
               self.mode == contact.mode and \
               self.sat == contact.sat and \
               self.prop_mode_sat == contact.prop_mode_sat
    

    def add_field(self,field,value):
        self.other[field]=value

    @classmethod
    def from_json(cls,json_obj):
        c = cls(json_obj["cid"], json_obj["my_callsign"], json_obj["their_callsign"], json_obj["time"], json_obj["band"], json_obj["mode"], json_obj["sat"], json_obj["prop_mode_sat"], json_obj[" comment"])
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
        if contact.their_callsign in self.contacts:
            self.contacts[contact.their_callsign].append(contact)
        else:
            self.contacts[contact.their_callsign] = [contact]
        self.contacts_by_id.append(contact)

    def remove_contact(self,contact):
        return self.contacts[contact.their_callsign].remove(contact)

    def update_contact(self, contact):
        idx = self.contacts[contact.their_callsign].index(contact)
        self.contacts[contact.their_callsign][idx]=contact

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
    
    

    







    

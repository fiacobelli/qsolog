import sys
import models as m
import datetime as d

def start(fname):
    logbook = m.LogBook.load_logbook(fname)
    done = False
    while(not done):
        print("Enter q for qso, l to list QSOs, x to save and quit")
        i = input(">")
        process_cmd(i,logbook)
        done = i=='x' or i=='X'
    logbook.save_logbook()
    print("Logbook saved at:"+logbook.path)

def process_cmd(cmd,logbook):
    if cmd=='l' or cmd=='L':
        list_qsos(logbook)
    elif cmd=='q' or cmd=='Q':
        enter_qso(logbook)
    else:
        print("'"+cmd+"' is not a valid command.")

def list_qsos(logbook):
    for k in logbook.contacts:
        for qso in logbook.contacts[k]:
            print((qso.__dict__))


def enter_qso(logbook):
    cid = logbook.get_next_id()
    print("QSO # "+str(cid))
    my_call = input("Your callsign:")
    their_call =input("Their callsign:")
    time = d.datetime.now()
    band = input("Band (just number):")
    mode = input("Mode:")
    sat = input("Satellite (leave blank for none):")
    sat_prop = input("Satellite propagation (blank for none):")
    comments = input("Comments:")
    qso = m.Contact(cid,my_call,their_call,time,band,mode,sat,sat_prop,comments)
    insert_qso(qso,logbook)
    print("QSO entered:"+str(qso.__dict__))

def insert_qso(contact,logbook):
    logbook.add_contact(contact)
    return True




if __name__=="__main__":
    fname = sys.argv[1]
    start(fname)
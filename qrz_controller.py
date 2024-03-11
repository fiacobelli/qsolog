import external_strings as s
import urllib.parse
import urllib.request
import urllib.response
import xml.etree.ElementTree as et
import utils as u

QRZ_CALL_BASE_URL = "https://xmldata.qrz.com/xml/current/?"
QRZ_AGENT="qsolog1.0"
QRZ_VALUES = {}
QRZ_KEY = "Key"
QRZ_XMLNS = '{http://xmldata.qrz.com}'
QRZ_RESPONSE={}

def read_config():
    params=open('qrz.config','r').read().strip().split("\n")
    for p in params:
        key,value = p.split(",")
        QRZ_VALUES[key]=value
    return True

def connect_callisgn_lookup():
    read_config()
    values={'username':QRZ_VALUES[s.QRZ_USERNAME],
    'password':QRZ_VALUES[s.QRZ_PASSWORD],
    'agent':QRZ_AGENT}
    data = urllib.parse.urlencode(values)
    data = data.encode('ascii') # data should be bytes
    req = urllib.request.Request(QRZ_CALL_BASE_URL, data)
    resp = urllib.request.urlopen(QRZ_CALL_BASE_URL,data=data)
    return get_xml_attrib('Key',resp.read())

def get_xml_attrib(att,xmldoc):
    root = et.fromstring(xmldoc)
    elements = root.findall(".")
    target = root.findall('.//'+QRZ_XMLNS+att)
    print('.//'+att,target,"\n",elements)
    if len(target)>0:
        return target[0].text
    else:
        return None


def request_callsign(key,callsign):
    values={'callsign':callsign,
    's':key}
    data = urllib.parse.urlencode(values)
    data = data.encode('ascii') # data should be bytes
    req = urllib.request.Request(QRZ_CALL_BASE_URL, data)
    resp = urllib.request.urlopen(QRZ_CALL_BASE_URL,data=data)
    return resp.read()

if __name__=='__main__':
    #print(connect_callisgn_lookup())
    qrz_key = get_xml_attrib(QRZ_KEY,'<?xml version="1.0" encoding="utf-8" ?>\n<QRZDatabase version="1.36" xmlns="http://xmldata.qrz.com">\n<Session>\n<Key>b5e8cb910fd86164d5336ffccf4fca9f</Key>\n<Count>0</Count>\n<SubExp>Sun May 18 19:08:17 2025</SubExp>\n<GMTime>Sun Mar 10 21:58:27 2024</GMTime>\n<Remark>cpu: 0.014s</Remark>\n</Session>\n</QRZDatabase>')
    print(qrz_key)
    #print(request_callsign(qrz_key,'ke9fid'))
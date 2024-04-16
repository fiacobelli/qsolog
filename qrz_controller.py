import external_strings as s
import urllib.parse
import urllib.request
import urllib.response
import xml.etree.ElementTree as et
import utils as u
import ssl

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
    ssl._create_default_https_context = ssl._create_unverified_context
    data = urllib.parse.urlencode(values)
    data = data.encode('ascii') # data should be bytes
    req = urllib.request.Request(QRZ_CALL_BASE_URL, data)
    resp = urllib.request.urlopen(QRZ_CALL_BASE_URL,data=data)
    return get_xml_attrib('Key',resp.read())

def get_xml_attrib(att,xmldoc):
    root = et.fromstring(xmldoc)
    return get_child_node_val(att,root)

def get_child_node_val(att,root):
    target = root.findall('.//'+QRZ_XMLNS+att)
    print(target)
    if len(target)>0:
        return target[0].text
    else:
        return ""

def get_xml_error(xmldoc):
    msg = get_xml_attrib("Error",xmldoc)
    return msg

def request_callsign(key,callsign):
    values={'callsign':callsign,
    's':key}
    data = urllib.parse.urlencode(values)
    data = data.encode('ascii') # data should be bytes
    req = urllib.request.Request(QRZ_CALL_BASE_URL, data)
    resp = urllib.request.urlopen(QRZ_CALL_BASE_URL,data=data)
    return resp.read()

def populate_data(xml_info):
    root = et.fromstring(xml_info)
    err = get_xml_error(xml_info)
    if err:
        QRZ_RESPONSE = {"Error":err}
    else:
        QRZ_RESPONSE = {s.NAME:get_child_node_val('fname',root)+" "+get_child_node_val('name',root),
                        s.GRIDSQUARE:get_child_node_val('grid',root),
                        s.ADDRESS:get_child_node_val('addr1',root)+","+get_child_node_val('addr2',root),
                        s.STATE:get_child_node_val('state',root),
                        s.COUNTRY:get_child_node_val('land',root),
                        s.LAT:get_child_node_val('lat',root),
                        s.LON:get_child_node_val('lon',root),
                        'XML_RESPONSE':xml_info}
    return QRZ_RESPONSE
    
def lookup_callsign(callsign):
    try:
        qrz_key = connect_callisgn_lookup()
        call_data = request_callsign(qrz_key,callsign)
        return populate_data(call_data)
    except Exception as e:
        return {'Error':'There was a problem retrieving data from QRZ:'+str(e)}

if __name__=='__main__':
    print(lookup_callsign("n0lsr"))
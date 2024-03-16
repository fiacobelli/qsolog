import urllib.parse
import urllib.request
import urllib.response
import json

base_url = "https://api.pota.app/"
def read_config():
    params=open('qrz.config','r').read().strip().split("\n")
    for p in params:
        key,value = p.split(",")
        QRZ_VALUES[key]=value
    return True

def get_pota_info(potaref):
    doc = urllib.request.urlopen(base_url+"/park/"+potaref).read()
    data = json.loads(doc)
    return data

def get_pota_spots():
    doc = urllib.request.urlopen(base_url+"spot/").read()
    data = json.loads(doc)
    return data



if __name__=="__main__":
    print(get_pota_spots())
    print(get_pota_info("K-2194"))

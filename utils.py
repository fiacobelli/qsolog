import datetime
import xml.etree.ElementTree as et
import math

def within_thirty_minutes(datetime1,datetime2):
    tdelta = datetime1-datetime2
    return tdelta.minutes<=30

def xml_dict(node, path="", dic =None):
    if dic == None:
        dic = {}
    name_prefix = path + ("." if path else "") + node.tag
    numbers = set()
    for similar_name in dic.keys():
        if similar_name.startswith(name_prefix):
            numbers.add(int (similar_name[len(name_prefix):].split(".")[0] ) )
    if not numbers:
        numbers.add(0)
    index = max(numbers) + 1
    name = name_prefix + str(index)
    dic[name] = node.text + "<...>".join(childnode.tail
                                         if childnode.tail is not None else
                                         "" for childnode in node)
    for childnode in node:
        xml_dict(childnode, name, dic)
    return dic

def distance_on_earth(lat1,long1,lat2,long2,unit='km'):
    # lats and longs need to be converted to radians.
    lat1 = lat1*math.pi/180
    lat2 = lat2*math.pi/180
    long1 = long1*math.pi/180
    long2 = long2*math.pi/180
    #d = 2R × sin⁻¹(√[sin²((θ₂ - θ₁)/2) + cosθ₁ × cosθ₂ × sin²((φ₂ - φ₁)/2)])
    a = 6378 #earth's radius in km at equator
    lats = math.sin((lat2-lat1)/2)**2
    lons = math.sin((long2-long1)/2)**2
    coses = math.cos(lat1)*math.cos(lat2)
    d = 2*a*math.asin(math.sqrt(lats+coses*lons))
    if unit=='mi':
        return d/1.6
    else:
        return d

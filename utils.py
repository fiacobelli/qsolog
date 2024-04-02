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
    #d = 2R × sin⁻¹(√[sin²((θ₂ - θ₁)/2) + cosθ₁ × cosθ₂ × sin²((φ₂ - φ₁)/2)])
    R = 6371 #earth's radius in km
    d = 2*R*math.asin(math.sqrt((lat1-lat2)/2) + math.cos(lat1)*math.cos(lat2)*math.asin((long1-long2)/2))
    if unit=='mi':
        return d/1.6
    else:
        return d

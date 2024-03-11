import datetime
import xml.etree.ElementTree as et

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
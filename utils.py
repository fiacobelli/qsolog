import datetime
def within_thirty_minutes(datetime1,datetime2):
    tdelta = datetime1-datetime2
    return tdelta.minutes<=30


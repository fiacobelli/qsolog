import sqlite3

def create_contacts_table(dbname):
    try:
        conn = sqlite3.connect(dbname)
        # cursor object
        cursor_obj = conn.cursor()
        
        # Creating table
        table = """ CREATE TABLE IF NOT EXISTS CONTACTS (
                    QSO_ID integer PRIMARY KEY AUTOINCREMENT,
                    LOG_ID integer NOT NULL,
                    MY_CALLSIGN varchar(9),
                    CALL varchar(9),
                    QSO_DATE char(10),
                    TIME_ON char(8),
                    BAND varchar(20),
                    MODE varchar(15),
                    SAT_MODE varchar(15),
                    SAT_NAME varchar(50),
                    COMMENT varchar(255)

                ); """
        
        cursor_obj.execute(table)
        
        print("Table contacts is Ready")

    # Handle errors
    except sqlite3.Error as error:
        print('Error occurred - ', error)
    
    # Close DB Connection irrespective of success
    # or failure
    finally:
    
        if conn:
            conn.close()
            print('SQLite Connection closed')


def create_contact_additional_table(dbname):
    try:
        conn = sqlite3.connect(dbname)
        # cursor object
        cursor_obj = conn.cursor()
        
        # Creating table
        table = """ CREATE TABLE IF NOT EXISTS CONTACT_ADDITIONAL (
                    QSO_ID integer PRIMARY KEY,
                    FIELD varchar(20),
                    VALUE varchar(255)

                ); """
        
        cursor_obj.execute(table)
        
        print("Table contact_addional is Ready")

    # Handle errors
    except sqlite3.Error as error:
        print('Error occurred - ', error)
    
    # Close DB Connection irrespective of success
    # or failure
    finally:
    
        if conn:
            conn.close()
            print('SQLite Connection closed')



def create_logbook_table(dbname):
    try:
        conn = sqlite3.connect(dbname)
        # cursor object
        cursor_obj = conn.cursor()
        
        # Creating table
        table = """ CREATE TABLE IF NOT EXISTS LOGBOOKS (
                    LOG_ID integer PRIMARY KEY AUTOINCREMENT,
                    LOGBOOK_NAME varchar(50)

                ); """
        
        cursor_obj.execute(table)
        
        print("Table logbook is Ready")

    # Handle errors
    except sqlite3.Error as error:
        print('Error occurred - ', error)
    
    # Close DB Connection irrespective of success
    # or failure
    finally:
    
        if conn:
            conn.close()
            print('SQLite Connection closed')

def create_tables(database):
    create_logbook_table(database)
    create_contacts_table(database)
    create_contact_additional_table(database)

if __name__=='__main__':
    create_tables("test")
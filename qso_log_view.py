import sys, datetime
from PyQt6 import uic
from PyQt6.QtWidgets import *
from PyQt6.QtGui import *
from PyQt6.QtCore import Qt, QTimer, QDateTime, QDate, QTime, QObject, QRunnable, QThreadPool, QThread, pyqtSignal
import webbrowser
from qsomain import Ui_MainWindow
from config_dialog import Form
import models as m
import pota_model as pomo
import qso_controller as qsoc
import qrz_controller as qrz
import pota_controller as pc
import external_strings as s

class Worker(QRunnable):

    finished = pyqtSignal(dict)
    
    def __init__(self,fun,info=None):
       super(Worker, self).__init__()
       self.info = info
       self.fn = fun
       self.data = {}
       self.signals = WorkerSignals()

    def run(self):
        # Task that needs multithreading
        try:
            self.data = self.fn(self.info)
        except:
            exctype, value = sys.exc_info()[:2]
            data = {'Error':str(exctype)+" - "+ str(value)}
            self.signals.error.emit(self.data)
        
        self.signals.result.emit(self.data)
        self.signals.finished.emit()

class WorkerSignals(QObject):
    finished = pyqtSignal()
    error = pyqtSignal(dict)
    result = pyqtSignal(dict)


class MainWindow(QMainWindow, Ui_MainWindow):
    def __init__(self, *args, obj=None, **kwargs):
        super(MainWindow, self).__init__(*args, **kwargs)
        self.threadpool = QThreadPool()
        self.setupUi(self)
        self.setup_configurations()
        self.setup_basics()
        self.setup_menu()
        self.setup_buttons()
        self.setup_other_events()
        


    def setup_configurations(self):
        self.myconfig,self.qrzconfig,self.lastconf,self.potaconf = qsoc.read_configurations()
        self.my_callsign = self.myconfig[s.MY_CALLSIGN]
        self.groupBox.setTitle("DE "+self.my_callsign)
        self.statusbar.showMessage("Logging QSO DE "+self.my_callsign+" on "+self.lastconf[s.CURRENT_LOGBOOK])
        self.logbook_change = False
        self.restore_previous_log()
        self.restore_previous_settings()
    

        
    def restore_previous_log(self):
        if len(self.lastconf[s.CURRENT_LOGBOOK])<3:
            return False
        self.logbook = qsoc.load_logbook(self.lastconf[s.CURRENT_LOGBOOK])
        self.lbmodel = m.LogBookTableModel(self.logbook)
        self.logListTableView.setSortingEnabled(True)
        self.logListTableView.setModel(self.lbmodel)
        return True


    def restore_previous_settings(self):
        tabopen = int(self.lastconf[s.CURRENT_MODE])
        self.specialFieldsTabWidget.setCurrentIndex(tabopen)
        width = int(self.lastconf[s.UI_WIDTH])
        height = int(self.lastconf[s.UI_HEIGHT])
        self.resize(width,height)


    def setup_basics(self):
        # Dates, combo boxes filling up, etc.
        self.dateEdit.setDate(QDateTime.currentDateTimeUtc().date())
        self.timeEdit.setTime(QDateTime.currentDateTimeUtc().time())
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.update_all)
        self.timer.start(5000) #Update every 5 seconds.
        self.localDateTimeEdit.setDateTime(QDateTime.currentDateTime())
        self.zuluDateTimeEdit.setDateTime(QDateTime.currentDateTime())
        self.theirCallLineEdit.textChanged.connect(self.always_upper)
        self.bandComboBox.addItems(qsoc.get_bands())
        self.bandComboBox.setCurrentIndex(0)
        self.modeComboBox.addItems(qsoc.get_modes())
        self.bandComboBox.currentIndexChanged.connect(self.update_frequency)
        self.frequencyDoubleSpinBox.valueChanged.connect(self.update_band)
        self.logListTableView.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.logListTableView.doubleClicked.connect(self.load_contact)
        self.pushButtonPotaSpots.clicked.connect(self.load_pota_spots)
        self.tableViewPotaSpots.doubleClicked.connect(self.select_pota_spot)
        self.current_contact = None

    def load_contact(self):
        areyousure = QMessageBox(self)
        areyousure.setWindowTitle("WARNING!")
        areyousure.setText("You are about to overwrite any contact you are working on already. Do you want to proceed?")
        areyousure.setStandardButtons(QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No)
        areyousure.setIcon(QMessageBox.Icon.Warning)
        option = areyousure.exec()
        if (option == QMessageBox.StandardButton.Yes):
            print(self.logListTableView.selectedIndexes()[0].row(),self.logListTableView.selectedIndexes()[0].data() )
            self.logListTableView.selectRow(self.logListTableView.selectedIndexes()[0].row())
            print(self.logListTableView.selectedIndexes()[0].row(),self.logListTableView.selectedIndexes()[0].data() )
            self.load_qso_fields(int(self.logListTableView.selectedIndexes()[0].data()),self.logListTableView.selectedIndexes()[0].row()) # Pass the ID of the contact.
            self.updateButtonBox.setVisible(True)
            self.saveQSOButtonBox.setVisible(False)
            

    def setup_buttons(self):
        self.saveQSOButtonBox.accepted.connect(self.save_qso)
        self.saveQSOButtonBox.clicked.connect(self.discard_qso)
        updatebtn = QPushButton("Update")
        deletebtn = QPushButton("Delete")
        cancelbtn = QPushButton("Cancel")
        self.updateButtonBox.addButton(updatebtn,QDialogButtonBox.ButtonRole.AcceptRole)
        self.updateButtonBox.addButton(deletebtn,QDialogButtonBox.ButtonRole.RejectRole)
        self.updateButtonBox.addButton(cancelbtn,QDialogButtonBox.ButtonRole.HelpRole) #just to have a separate role.
        self.updateButtonBox.accepted.connect(self.update_qso)
        self.updateButtonBox.rejected.connect(self.delete_qso)
        self.updateButtonBox.helpRequested.connect(lambda:self.discard_qso(cancelbtn))
        self.updateButtonBox.setVisible(False)
        self.lookupPushButton.clicked.connect(self.openqrz)
        



    def setup_menu(self):
        self.action_Open_Logbook.triggered.connect(self.open_logbook)
        self.action_Save_Logbook.triggered.connect(self.save_logbook)
        self.action_New_Logbook.triggered.connect(self.new_logbook)
        self.action_Exit.triggered.connect(self.close)
        self.action_My_Information.triggered.connect(lambda:self.open_config('mine'))
        self.actionQRZ_Interaction.triggered.connect(lambda:self.open_config('qrz'))
        
        self.action_ADI_File.triggered.connect(self.logbook2adi)
        self.actionImport_A_DI.triggered.connect(self.adi2logbook)


    def setup_other_events(self):
        self.theirCallLineEdit.editingFinished.connect(self.fill_callsign_details)
        self.theirParkIDLineEdit.editingFinished.connect(self.fill_pota_data)
        self.searchLineEdit.textChanged.connect(self.search_qsos)
        

    # Actions that happen when you move around.
    def fill_callsign_details(self):
        worker = Worker(qrz.lookup_callsign,self.theirCallLineEdit.text())
        worker.signals.result.connect(self.update_callsign_data)
        self.threadpool.start(worker)
        self.update_qso_clock()
        self.search_qsos(self.theirCallLineEdit.text())
        

    def fill_pota_data(self):
        worker = Worker(pc.get_pota_info,self.theirParkIDLineEdit.text())
        worker.signals.result.connect(self.update_pota_data)
        self.threadpool.start(worker)

    def update_pota_data(self,data):
        if len(data)<5:
            return None 
        self.theirParkNameLineEdit.setText(data["name"])
        self.potaGridLineEdit.setText(data['grid4'])
        self.potaLatLineEdit.setText(str(data['latitude']))
        self.potaLonLineEdit.setText(str(data['longitude']))
        self.potaStateLineEdit.setText(data['locationDesc'][-2:])

    
    def update_qso_clock(self):
        self.dateEdit.setDate(QDateTime.currentDateTimeUtc().date())
        self.timeEdit.setTime(QDateTime.currentDateTimeUtc().time())
        
    def update_frequency(self):
        low_freq,high_freq = s.bands[self.bandComboBox.currentText()]
        if self.frequencyDoubleSpinBox.value()<low_freq or self.frequencyDoubleSpinBox.value()>high_freq:
            self.frequencyDoubleSpinBox.setValue(low_freq/1000000)
            self.frequencyTXDoubleSpinBox.setValue(low_freq/1000000)

    def update_band(self):
        band = ""
        freq = self.frequencyDoubleSpinBox.value()*1000000
        for b in s.bands:
            low,high = s.bands[b]
            if freq>=low and freq<=high:
                band = b
                self.bandComboBox.setCurrentText(b)
        #self.bandComboBox.setCurrentIndex(self.bandComboBox.findText(band))
        return None
    
    def openqrz(self):
        webbrowser.open(s.QRZ_LOOKUP+self.theirCallLineEdit.text())

    def update_callsign_data(self,qrz_data):
        if 'Error' in qrz_data:
            self.statusbar.showMessage(qrz_data['Error'])
            return False
        self.qsoNameLineEdit.setText(qrz_data[s.NAME])
        self.qsoAddressLineEdit.setText(qrz_data[s.ADDRESS])
        self.qsoCountryLineEdit.setText(qrz_data[s.COUNTRY])
        self.qsoStateLineEdit.setText(qrz_data[s.STATE])
        self.qsoGridLineEdit.setText(qrz_data[s.GRIDSQUARE])
        self.latLineEdit.setText(qrz_data[s.LAT])
        self.lonLineEdit.setText(qrz_data[s.LON])
        self.statusbar.showMessage(f"contact is {qsoc.distance_from_me(qrz_data[s.LAT],qrz_data[s.LON],self.myconfig[s.MY_LAT],self.myconfig[s.MY_LON])} km. away")
        return True
        
    def search_qsos(self,txt):
        self.logListTableView.clearSelection()
        if not txt:
            # Empty string, don't search.
            return

        matching_items = qsoc.get_matching_rows(self.logbook,txt)
        if matching_items:
            # we have found something
            for item in range(len(self.logbook.contacts_by_id)):
                self.logListTableView.hideRow(item)
            for item in matching_items:
                self.logListTableView.showRow(item)
    
#### Open Config dialogs.
    def open_config(self,config):
        dlg = Form(self)
        if config=='mine':
            dlg.make_window("./qsolog.config")
            dlg.setWindowTitle("My Information")   
        elif config=='qrz':
            dlg.make_window("./qrz.config")
            dlg.setWindowTitle("My QRZ Information") 
        dlg.setParent(self)
        dlg.exec()


#### Functions related to the pota Spots box.
    def load_pota_spots(self):
        pota_loader = Worker(pc.get_pota_spots,None)
        pota_loader.signals.result.connect(self.update_pota_data)
        self.threadpool.start(pota_loader)
        potamodel = pomo.PotaModel()
        self.spots = potamodel.json2table(pc.get_pota_spots())
        self.pmodel = pomo.PotaTableModel(self.spots[0],self.spots[1])
        self.pmodel.layoutChanged.emit()
        self.tableViewPotaSpots.setModel(self.pmodel)
        return True


    def select_pota_spot(self):
        print(self.tableViewPotaSpots.selectedIndexes()[0].row(),self.tableViewPotaSpots.selectedIndexes()[0].data() )
        self.tableViewPotaSpots.selectRow(self.tableViewPotaSpots.selectedIndexes()[0].row())
        print(self.tableViewPotaSpots.selectedIndexes()[1].data())
        self.theirParkIDLineEdit.setText(self.tableViewPotaSpots.selectedIndexes()[3].data())
        self.theirCallLineEdit.setText(self.tableViewPotaSpots.selectedIndexes()[0].data())
        self.frequencyDoubleSpinBox.setValue(float(self.tableViewPotaSpots.selectedIndexes()[1].data())/1000)
        self.modeComboBox.setCurrentText(self.tableViewPotaSpots.selectedIndexes()[2].data())
        self.fill_pota_data()
        


#### Functions related to loading and saving QSOs
    def open_logbook(self):
        filename = QFileDialog.getOpenFileName(self, 'Open file', 
   './',"Log files (*.log)")
        self.logbook = qsoc.load_logbook(filename[0])
        self.lbmodel = m.LogBookTableModel(self.logbook)
        self.logListTableView.setModel(self.lbmodel)
        self.update_model()
        return True

    def new_logbook(self):
        filename = QFileDialog.getSaveFileName(self, 'New logbook','./', 'Log files (*.log)')[0]
        self.logbook = qsoc.get_new_logbook(self.my_callsign,filename)
        self.lbmodel = m.LogBookTableModel(self.logbook)
        self.logListTableView.setModel(self.lbmodel)
        return True

    def discard_qso(self,btn):
        if btn.text()=="Discard" or btn.text()=="Cancel":
            self.clear_qso_fields()
            self.updateButtonBox.setVisible(False)
            self.saveQSOButtonBox.setVisible(True)

    def save_qso(self):
        print("Save")
        if (self.logbook and len(self.theirCallLineEdit.text())>1):
            state,grid,lat,lon = self.get_location()
            qsoc.insert_contact(self.logbook,self.my_callsign,self.theirCallLineEdit.text(),self.dateEdit.date().toPyDate(),
                            self.timeEdit.time().toPyTime(), self.bandComboBox.currentText(),self.modeComboBox.currentText(),
                            self.satNameComboBox.currentText(),self.satModeLineEdit.text(), self.commentsPlainTextEdit.toPlainText(),
                            POTA_REF=self.theirParkIDLineEdit.text(),NOTES=self.theirParkNameLineEdit.text(),
                            RST_RCVD=self.RSTReceivedLineEdit.text(),RST_SENT=self.RSTSendLineEdit.text(),
                            FREQ = self.frequencyDoubleSpinBox.value(), FREQ_RX=self.frequencyTXDoubleSpinBox.value(),
                            STATE = state, LAT=lat, LON=lon,GRIDSQUARE=grid,NAME=self.qsoNameLineEdit.text(),
                            ADDRESS = self.qsoAddressLineEdit.text(), COUNTRY=self.qsoCountryLineEdit.text(),
                            CONTEST_ID = self.contestNameComboBox.currentText(), ARRL_SECT = self.arrlSectionLineEdit.text(),
                            SRX = self.serialRcvLineEdit.text(), STX=self.serialSentSpinBox.text(),
                            MY_STATE = self.myconfig[s.MY_STATE],MY_GRID=self.myconfig[s.MY_GRID],
                            MY_LAT=self.myconfig[s.MY_LAT], MY_LON=self.myconfig[s.MY_LON],
                            MY_POTA_REF = self.potaconf[s.MY_POTA_REF]
                            )
            self.update_model()
        else:
            self.statusbar.showMessage("No Callsign to save")
        self.qso_fields_after_save()


    def update_qso(self):
        print("Updating")
        if self.current_contact:
            contact = self.current_contact
        else:
            self.statusbar.showMessage("No QSO to update")
            return True
        
        if (self.logbook and len(self.theirCallLineEdit.text())>1):
            state,grid,lat,lon = self.get_location()
            qsoc.update_contact(contact,self.my_callsign,self.theirCallLineEdit.text(),self.dateEdit.date().toPyDate(),
                            self.timeEdit.time().toPyTime(), self.bandComboBox.currentText(),self.modeComboBox.currentText(),
                            self.satNameComboBox.currentText(),self.satModeLineEdit.text(), self.commentsPlainTextEdit.toPlainText(),
                            POTA_REF=self.theirParkIDLineEdit.text(),NOTES=self.theirParkNameLineEdit.text(),
                            RST_RCVD=self.RSTReceivedLineEdit.text(),RST_SENT=self.RSTSendLineEdit.text(),
                            FREQ = self.frequencyDoubleSpinBox.value(), FREQ_RX=self.frequencyTXDoubleSpinBox.value(),
                            STATE = state, LAT=lat, LON=lon,GRIDSQUARE=grid,NAME=self.qsoNameLineEdit.text(),
                            ADDRESS = self.qsoAddressLineEdit.text(), COUNTRY=self.qsoCountryLineEdit.text(),
                            CONTEST_ID = self.contestNameComboBox.currentText(), ARRL_SECT = self.arrlSectionLineEdit.text(),
                            SRX = self.serialRcvLineEdit.text(), STX=self.serialSentSpinBox.value(),
                            MY_STATE = self.myconfig[s.MY_STATE],MY_GRID=self.myconfig[s.MY_GRID],
                            MY_LAT=self.myconfig[s.MY_LAT], MY_LON=self.myconfig[s.MY_LON],
                            MY_POTA_REF = self.potaconf[s.MY_POTA_REF]
                            )
            self.update_model()
            self.statusbar.showMessage("QSO Updated")
            self.current_contact = None
        else:
            self.statusbar.showMessage("No Callsign to update")
        self.qso_fields_after_save()

    def delete_qso(self):
        if self.current_contact:
            contact = self.current_contact
        else:
            self.statusbar.showMessage("No QSO to delete")
            return True
        self.logbook.remove_contact(contact)
        self.statusbar.showMessage("QSO Deleted")
        self.update_model()
        self.clear_qso_fields()
        return None

    def qso_fields_after_save(self):
        #In a contest...
        
        if self.specialFieldsTabWidget.currentIndex() == 4:
            self.statusbar.showMessage("Saved in CONTEST mode")
            cntst_name = self.contestNameComboBox.currentText()
            cntst_serial =self.serialSentSpinBox.value()
            rst_rcvd = self.RSTReceivedLineEdit.text()
            rst_snt = self.RSTSendLineEdit.text()
            band = self.bandComboBox.currentIndex()
            freq = self.frequencyDoubleSpinBox.value()
            power = self.powerLineEdit.text()
            arrlsect = self.arrlSectionLineEdit.text()
            mode = self.modeComboBox.currentText()
            self.clear_qso_fields()
            self.contestNameComboBox.setCurrentText(cntst_name)
            self.serialSentSpinBox.setValue(cntst_serial+1)
            self.RSTReceivedLineEdit.setText(rst_rcvd)
            self.RSTSendLineEdit.setText(rst_snt)
            self.bandComboBox.setCurrentIndex(band)
            self.powerLineEdit.setText(power)
            self.arrlSectionLineEdit.setText(arrlsect)
            self.modeComboBox.setCurrentText(mode)
        else:
            self.clear_qso_fields()
        self.updateButtonBox.setVisible(False)
        self.saveQSOButtonBox.setVisible(True)
        
    def load_qso_fields(self,data,idx):
        self.logListTableView.selectRow(idx)
        contact: m.Contact = self.logbook.get_contact_by_id(data)
        self.current_contact_idx = idx
        self.current_contact = contact
        self.theirCallLineEdit.setText(contact.get_attr('call'))
        self.dateEdit.setDate(contact.get_attr('qso_date'))
        self.timeEdit.setTime(contact.get_attr('qso_time')), 
        self.bandComboBox.setCurrentText(contact.get_attr('band'))
        self.modeComboBox.setCurrentText(contact.get_attr('mode'))
        self.satNameComboBox.setCurrentText(contact.get_attr('sat_name'))
        self.satModeLineEdit.setText(contact.get_attr('sat_mode')) 
        self.commentsPlainTextEdit.setPlainText(contact.get_attr('comment'))
        self.theirParkIDLineEdit.setText(contact.get_attr(s.POTA_REF))
        self.theirParkNameLineEdit.setText(contact.get_attr(s.NOTES))
        self.RSTReceivedLineEdit.setText(contact.get_attr(s.RST_RCVD))
        self.RSTSendLineEdit.setText(contact.get_attr(s.RST_SENT))
        self.frequencyDoubleSpinBox.setValue(contact.get_attr(s.FREQ))
        self.frequencyTXDoubleSpinBox.setValue(contact.get_attr(s.FREQ_RX))
        self.qsoStateLineEdit.setText(contact.get_attr(s.STATE))
        self.potaStateLineEdit.setText(contact.get_attr(s.STATE))
        self.latLineEdit.setText(contact.get_attr(s.LAT))
        self.lonLineEdit.setText(contact.get_attr(s.LON))
        self.potaLatLineEdit.setText(contact.get_attr(s.LAT))
        self.potaLonLineEdit.setText(contact.get_attr(s.LON))
        self.qsoGridLineEdit.setText(contact.get_attr(s.GRIDSQUARE))
        self.potaGridLineEdit.setText(contact.get_attr(s.GRIDSQUARE))
        self.qsoNameLineEdit.setText(contact.get_attr(s.NAME))
        self.qsoAddressLineEdit.setText(contact.get_attr(s.ADDRESS))
        self.qsoCountryLineEdit.setText(contact.get_attr(s.COUNTRY))
        self.contestNameComboBox.setCurrentText(contact.get_attr(s.CONTEST_ID))
        self.arrlSectionLineEdit.setText(contact.get_attr(s.ARRL_SECT))
        self.serialRcvLineEdit.setText(contact.get_attr(s.SRX))
        self.serialSentSpinBox.setValue(0 if contact.get_attr(s.STX)=='' else int(contact.get_attr(s.STX)))
        # Ver como deal con esto. self.myconfig[s.MY_STATE],MY_GRID=self.myconfig[s.MY_GRID],
        #                    MY_LAT=self.myconfig[s.MY_LAT], MY_LON=self.myconfig[s.MY_LON],
        #                    MY_POTA_REF = self.potaconf[s.MY_POTA_REF]
    

# Export/import functions
    def logbook2adi(self):
        filename = QFileDialog.getSaveFileName(self, 'New logbook','./', 'Adi files (*.adi)')[0]
        qsoc.logbook2adi(self.logbook,filename)

    def adi2logbook(self):
        filename = QFileDialog.getOpenFileName(self, 'Open file', 
        './',"Adi files (*.adi)")
        self.logbook = qsoc.adifile2logbook(self.logbook,filename[0],self.statusbar)
        self.update_model()



# Considerations for a qso
    def get_location(self):
        state = self.qsoStateLineEdit.text()
        grid = self.qsoGridLineEdit.text()
        lat = self.latLineEdit.text()
        lon = self.lonLineEdit.text()
        # This checks that IF your QSO was POTA Hunt or SOTA hunt, location is that of the park or summit
        if len(self.potaStateLineEdit.text())>2:
            state = self.potaStateLineEdit.text()[-2:]
        if len(self.potaGridLineEdit.text())>2:
            grid = self.potaGridLineEdit.text()
        if len(self.potaLatLineEdit.text())>2:
            lat = self.potaLatLineEdit.text()
        if len(self.potaLonLineEdit.text())>2:
            lon = self.potaLonLineEdit.text()
        return(state,grid,lat,lon)
        

# Updating elements in the view.  
    def update_model(self):
        self.lbmodel.layoutChanged.emit()
        #model = qsoc.model_qsos_for_table(self.logbook)
        #self.logListTableView.setModel(model)
        self.logbook_change = True
        self.updateButtonBox.setVisible(False)
        self.saveQSOButtonBox.setVisible(True)
        

    def clear_qso_fields(self):
        print("Clear")
        self.theirCallLineEdit.clear()
        self.dateEdit.setDate(QDate.currentDate())
        self.timeEdit.setTime(QTime.currentTime())
        # self.bandComboBox.currentText()
        # self.modeComboBox.currentText()
        # self.satNameComboBox.currentText()
        # self.satModeLineEdit.text()
        self.commentsPlainTextEdit.clear()
        self.theirParkIDLineEdit.clear()
        self.theirParkNameLineEdit.clear()
        self.RSTReceivedLineEdit.clear()
        self.RSTSendLineEdit.clear()
        self.frequencyDoubleSpinBox.setValue(7.0)
        self.frequencyTXDoubleSpinBox.setValue(7.0)
        for i in range(self.generalInfoFormLayout.rowCount()):
            li: QLineEdit = self.generalInfoFormLayout.itemAt(i,QFormLayout.ItemRole.FieldRole).widget()
            li.clear()
        for i in range(self.formLayout.rowCount()):
            li: QLineEdit = self.formLayout.itemAt(i,QFormLayout.ItemRole.FieldRole).widget()
            li.clear()
        for i in range(self.formLayout_2.rowCount()):
            li: QLineEdit = self.formLayout_2.itemAt(i,QFormLayout.ItemRole.FieldRole).widget()
            li.clear()
        for i in range(self.formLayout_4.rowCount()):
            li: QLineEdit = self.formLayout_4.itemAt(i,QFormLayout.ItemRole.FieldRole).widget()
            li.clear()
        

# Functions related to the timer and updating stuff at intervals.
    def update_all(self):
        self.localDateTimeEdit.setDateTime(QDateTime.currentDateTime())
        self.zuluDateTimeEdit.setDateTime(QDateTime.currentDateTime())
        stsmsg = self.statusbar.currentMessage()
        self.statusbar.clearMessage()
        self.save_logbook()
        self.statusbar.showMessage(stsmsg)

    def save_logbook(self):
        if self.logbook_change:
            qsoc.save_logbook(self.logbook)
            self.logbook_change = False
            self.statusbar.showMessage("Saving logbook...")

# App control
    def closeEvent(self,event):
        self.save_logbook()
        qsoc.save_last_state(self)
        event.accept()
        

# Always uppercase callsign.
    def always_upper(self,comp):
        self.theirCallLineEdit.setText(self.theirCallLineEdit.text().upper())

app = QApplication(sys.argv)

window = MainWindow()
window.show()
app.exec()
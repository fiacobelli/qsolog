import sys, datetime
from PyQt6 import uic
from PyQt6.QtWidgets import *
from PyQt6.QtGui import *
from PyQt6.QtCore import QTimer, QDateTime, QDate, QTime

from qsomain import Ui_MainWindow
import models as m
import qso_controller as qsoc

class MainWindow(QMainWindow, Ui_MainWindow):
    def __init__(self, *args, obj=None, **kwargs):
        super(MainWindow, self).__init__(*args, **kwargs)
        self.setupUi(self)
        self.setup_configurations()
        self.setup_basics()
        self.setup_menu()
        self.setup_buttons()

    def setup_configurations(self):
        self.my_callsign = "KE9FID"
        self.groupBox.setTitle("DE "+self.my_callsign)
        self.statusbar.showMessage("Logging QSO DE "+self.my_callsign)
        self.logbook_change = False

    def setup_basics(self):
        # Dates
        self.dateEdit.setDate(QDate.currentDate())
        self.timeEdit.setTime(QTime.currentTime())
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.update_all)
        self.timer.start(5000) #Update every 5 seconds.
        self.localDateTimeEdit.setDateTime(QDateTime.currentDateTime())
        self.zuluDateTimeEdit.setDateTime(QDateTime.currentDateTime())
        self.theirCallLineEdit.textChanged.connect(self.always_upper)
        self.bandComboBox.addItems(qsoc.get_bands())
        self.modeComboBox.addItems(['USB','LSB','AM','FM','OLIVIA'])


    def setup_buttons(self):
        self.saveQSOButtonBox.accepted.connect(self.save_qso)

    def setup_menu(self):
        self.action_Open_Logbook.triggered.connect(self.open_logbook)
        self.action_Save_Logbook.triggered.connect(self.save_logbook)
        self.action_New_Logbook.triggered.connect(self.new_logbook)
        self.action_Exit.triggered.connect(self.close)

    


#### Functions related to loading and saving QSOs
    def open_logbook(self):
        filename = QFileDialog.getOpenFileName(self, 'Open file', 
   './',"Log files (*.log)")
        self.logbook = qsoc.load_logbook(filename[0])
        self.update_model()
        return True

    def new_logbook(self):
        filename = QFileDialog.getSaveFileName(self, 'New logbook','./', 'log')[0]
        self.logbook = qsoc.get_new_logbook(self.my_callsign,filename)
        return True


    def save_qso(self):
        qsoc.insert_contact(self.logbook,self.my_callsign,self.theirCallLineEdit.text(),self.dateEdit.date().toPyDate(),
                            self.timeEdit.time().toPyTime(), self.bandComboBox.currentText(),self.modeComboBox.currentText(),
                            self.satNameComboBox.currentText(),self.satModeLineEdit.text(), self.commentsPlainTextEdit.toPlainText(),
                            POTA_REF=self.theirParkIDLineEdit.text(),NOTES=self.theirParkNameLineEdit.text(),
                            RST_RCVD=self.RSTReceivedLineEdit.text(),RST_SENT=self.RSTSendLineEdit.text(),
                            FREQ = self.frequencySpinBox.text(), FREQ_RX=self.frequencyTXSpinBox.text()
                            )
        self.update_model()
        self.clear_qso_fields()

# Updating elements in the view.  
    def update_model(self):
        model = qsoc.model_qsos_for_table(self.logbook)
        self.logListTableView.setModel(model)
        self.logbook_change = True

    def clear_qso_fields(self):
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
        self.frequencySpinBox.clear()
        self.frequencyTXSpinBox.clear()

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
        event.accept()

# Always uppercase callsign.
    def always_upper(self,comp):
        self.theirCallLineEdit.setText(self.theirCallLineEdit.text().upper())

app = QApplication(sys.argv)

window = MainWindow()
window.show()
app.exec()
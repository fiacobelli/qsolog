from PyQt6 import uic
from PyQt6.QtWidgets import *
from PyQt6.QtGui import *
from PyQt6.QtCore import QTimer, QDateTime, QDate, QTime
import sys

class Form(QDialog):

    def __init__(self, parent=None):
        super(Form, self).__init__(parent)
        

    def make_window(self,filename):
        self.filename = filename
        config_lines = open(filename,'r').read().strip().split("\n")
        layout = QFormLayout(self)
        for line in config_lines:
            if len(line)>1:
                key,value = line.split(",")
                label,lineEdit = self.get_form_components(key,value)
                layout.addRow(label,lineEdit)
        self.ok_cancel = QDialogButtonBox(QDialogButtonBox.StandardButton.Save|QDialogButtonBox.StandardButton.Cancel)
        self.edit = QLineEdit("Write my name here")
        
        layout.addWidget(self.ok_cancel)
        # Set dialog layout
        self.setLayout(layout)
        # Add button signal to greetings slot
        self.ok_cancel.accepted.connect(self.save_config)
        self.ok_cancel.rejected.connect(self.close)


    def get_form_components(self,key,value):
        name = key.replace("_"," ").title()
        label = QLabel(self)
        label.setText(name)
        label.setObjectName=key+"_Label"
        valueEdit = QLineEdit(self)
        valueEdit.setText(value)
        valueEdit.setObjectName(key)
        
        return (label,valueEdit)


    # Greets the user
    def list_config(self):
        params = []
        layout :QFormLayout = self.layout()
        for i in range(layout.rowCount()-1):
            li: QLineEdit = layout.itemAt(i,QFormLayout.ItemRole.FieldRole).widget()
            params.append(str(li.objectName())+","+str(li.text())+"\n")
        return params

    def save_config(self):
        params = self.list_config()
        with open(self.filename,'w') as file:
            file.writelines(params)
        print("Saved")
        self.close()

if __name__ == '__main__':
    # Create the Qt Application
    app = QApplication(sys.argv)
    # Create and show the form
    form = Form()
    form.make_window("qsolog.config")
    form.show()
    # Run the main Qt loop
    sys.exit(app.exec())
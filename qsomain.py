# Form implementation generated from reading ui file '.\qsologmainwindow.ui'
#
# Created by: PyQt6 UI code generator 6.6.1
#
# WARNING: Any manual changes made to this file will be lost when pyuic6 is
# run again.  Do not edit this file unless you know what you are doing.


from PyQt6 import QtCore, QtGui, QtWidgets


class Ui_MainWindow(object):
    def setupUi(self, MainWindow):
        MainWindow.setObjectName("MainWindow")
        MainWindow.resize(848, 654)
        self.centralwidget = QtWidgets.QWidget(parent=MainWindow)
        self.centralwidget.setObjectName("centralwidget")
        self.searchLineEdit = QtWidgets.QLineEdit(parent=self.centralwidget)
        self.searchLineEdit.setGeometry(QtCore.QRect(70, 10, 321, 22))
        self.searchLineEdit.setObjectName("searchLineEdit")
        self.label_13 = QtWidgets.QLabel(parent=self.centralwidget)
        self.label_13.setGeometry(QtCore.QRect(30, 10, 49, 16))
        self.label_13.setObjectName("label_13")
        self.groupBox = QtWidgets.QGroupBox(parent=self.centralwidget)
        self.groupBox.setGeometry(QtCore.QRect(20, 280, 811, 311))
        self.groupBox.setObjectName("groupBox")
        self.specialFieldsTabWidget = QtWidgets.QTabWidget(parent=self.groupBox)
        self.specialFieldsTabWidget.setGeometry(QtCore.QRect(490, 20, 301, 281))
        self.specialFieldsTabWidget.setObjectName("specialFieldsTabWidget")
        self.generalTabl = QtWidgets.QWidget()
        self.generalTabl.setObjectName("generalTabl")
        self.layoutWidget = QtWidgets.QWidget(parent=self.generalTabl)
        self.layoutWidget.setGeometry(QtCore.QRect(10, 10, 255, 201))
        self.layoutWidget.setObjectName("layoutWidget")
        self.generalInfoFormLayout = QtWidgets.QFormLayout(self.layoutWidget)
        self.generalInfoFormLayout.setContentsMargins(0, 0, 0, 0)
        self.generalInfoFormLayout.setObjectName("generalInfoFormLayout")
        self.label_20 = QtWidgets.QLabel(parent=self.layoutWidget)
        self.label_20.setObjectName("label_20")
        self.generalInfoFormLayout.setWidget(0, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_20)
        self.qsoNameLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget)
        self.qsoNameLineEdit.setObjectName("qsoNameLineEdit")
        self.generalInfoFormLayout.setWidget(0, QtWidgets.QFormLayout.ItemRole.FieldRole, self.qsoNameLineEdit)
        self.label_21 = QtWidgets.QLabel(parent=self.layoutWidget)
        self.label_21.setObjectName("label_21")
        self.generalInfoFormLayout.setWidget(1, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_21)
        self.qsoGridLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget)
        self.qsoGridLineEdit.setObjectName("qsoGridLineEdit")
        self.generalInfoFormLayout.setWidget(1, QtWidgets.QFormLayout.ItemRole.FieldRole, self.qsoGridLineEdit)
        self.label_22 = QtWidgets.QLabel(parent=self.layoutWidget)
        self.label_22.setObjectName("label_22")
        self.generalInfoFormLayout.setWidget(2, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_22)
        self.qsoAddressLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget)
        self.qsoAddressLineEdit.setObjectName("qsoAddressLineEdit")
        self.generalInfoFormLayout.setWidget(2, QtWidgets.QFormLayout.ItemRole.FieldRole, self.qsoAddressLineEdit)
        self.label_23 = QtWidgets.QLabel(parent=self.layoutWidget)
        self.label_23.setObjectName("label_23")
        self.generalInfoFormLayout.setWidget(3, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_23)
        self.qsoStateLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget)
        self.qsoStateLineEdit.setObjectName("qsoStateLineEdit")
        self.generalInfoFormLayout.setWidget(3, QtWidgets.QFormLayout.ItemRole.FieldRole, self.qsoStateLineEdit)
        self.label_24 = QtWidgets.QLabel(parent=self.layoutWidget)
        self.label_24.setObjectName("label_24")
        self.generalInfoFormLayout.setWidget(4, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_24)
        self.label_25 = QtWidgets.QLabel(parent=self.layoutWidget)
        self.label_25.setObjectName("label_25")
        self.generalInfoFormLayout.setWidget(6, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_25)
        self.qsoCountryLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget)
        self.qsoCountryLineEdit.setObjectName("qsoCountryLineEdit")
        self.generalInfoFormLayout.setWidget(6, QtWidgets.QFormLayout.ItemRole.FieldRole, self.qsoCountryLineEdit)
        self.latLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget)
        self.latLineEdit.setObjectName("latLineEdit")
        self.generalInfoFormLayout.setWidget(4, QtWidgets.QFormLayout.ItemRole.FieldRole, self.latLineEdit)
        self.lonLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget)
        self.lonLineEdit.setObjectName("lonLineEdit")
        self.generalInfoFormLayout.setWidget(5, QtWidgets.QFormLayout.ItemRole.FieldRole, self.lonLineEdit)
        self.label_28 = QtWidgets.QLabel(parent=self.layoutWidget)
        self.label_28.setObjectName("label_28")
        self.generalInfoFormLayout.setWidget(5, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_28)
        self.lookupPushButton = QtWidgets.QPushButton(parent=self.generalTabl)
        self.lookupPushButton.setGeometry(QtCore.QRect(90, 210, 75, 24))
        self.lookupPushButton.setObjectName("lookupPushButton")
        self.specialFieldsTabWidget.addTab(self.generalTabl, "")
        self.potaTab = QtWidgets.QWidget()
        self.potaTab.setObjectName("potaTab")
        self.layoutWidget1 = QtWidgets.QWidget(parent=self.potaTab)
        self.layoutWidget1.setGeometry(QtCore.QRect(10, 10, 199, 164))
        self.layoutWidget1.setObjectName("layoutWidget1")
        self.formLayout = QtWidgets.QFormLayout(self.layoutWidget1)
        self.formLayout.setContentsMargins(0, 0, 0, 0)
        self.formLayout.setObjectName("formLayout")
        self.label_10 = QtWidgets.QLabel(parent=self.layoutWidget1)
        self.label_10.setObjectName("label_10")
        self.formLayout.setWidget(0, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_10)
        self.theirParkIDLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget1)
        self.theirParkIDLineEdit.setObjectName("theirParkIDLineEdit")
        self.formLayout.setWidget(0, QtWidgets.QFormLayout.ItemRole.FieldRole, self.theirParkIDLineEdit)
        self.label_16 = QtWidgets.QLabel(parent=self.layoutWidget1)
        self.label_16.setObjectName("label_16")
        self.formLayout.setWidget(1, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_16)
        self.theirParkNameLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget1)
        self.theirParkNameLineEdit.setObjectName("theirParkNameLineEdit")
        self.formLayout.setWidget(1, QtWidgets.QFormLayout.ItemRole.FieldRole, self.theirParkNameLineEdit)
        self.label_17 = QtWidgets.QLabel(parent=self.layoutWidget1)
        self.label_17.setObjectName("label_17")
        self.formLayout.setWidget(2, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_17)
        self.potaStateLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget1)
        self.potaStateLineEdit.setObjectName("potaStateLineEdit")
        self.formLayout.setWidget(2, QtWidgets.QFormLayout.ItemRole.FieldRole, self.potaStateLineEdit)
        self.label_18 = QtWidgets.QLabel(parent=self.layoutWidget1)
        self.label_18.setObjectName("label_18")
        self.formLayout.setWidget(3, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_18)
        self.potaGridLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget1)
        self.potaGridLineEdit.setObjectName("potaGridLineEdit")
        self.formLayout.setWidget(3, QtWidgets.QFormLayout.ItemRole.FieldRole, self.potaGridLineEdit)
        self.label_26 = QtWidgets.QLabel(parent=self.layoutWidget1)
        self.label_26.setObjectName("label_26")
        self.formLayout.setWidget(4, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_26)
        self.potaLatLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget1)
        self.potaLatLineEdit.setObjectName("potaLatLineEdit")
        self.formLayout.setWidget(4, QtWidgets.QFormLayout.ItemRole.FieldRole, self.potaLatLineEdit)
        self.label_27 = QtWidgets.QLabel(parent=self.layoutWidget1)
        self.label_27.setObjectName("label_27")
        self.formLayout.setWidget(5, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_27)
        self.potaLonLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget1)
        self.potaLonLineEdit.setObjectName("potaLonLineEdit")
        self.formLayout.setWidget(5, QtWidgets.QFormLayout.ItemRole.FieldRole, self.potaLonLineEdit)
        self.specialFieldsTabWidget.addTab(self.potaTab, "")
        self.splitTab = QtWidgets.QWidget()
        self.splitTab.setObjectName("splitTab")
        self.label_19 = QtWidgets.QLabel(parent=self.splitTab)
        self.label_19.setGeometry(QtCore.QRect(10, 20, 81, 16))
        self.label_19.setObjectName("label_19")
        self.frequencyTXDoubleSpinBox = QtWidgets.QDoubleSpinBox(parent=self.splitTab)
        self.frequencyTXDoubleSpinBox.setGeometry(QtCore.QRect(100, 20, 101, 22))
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Policy.Maximum, QtWidgets.QSizePolicy.Policy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.frequencyTXDoubleSpinBox.sizePolicy().hasHeightForWidth())
        self.frequencyTXDoubleSpinBox.setSizePolicy(sizePolicy)
        self.frequencyTXDoubleSpinBox.setDecimals(5)
        self.frequencyTXDoubleSpinBox.setMaximum(7500000.99)
        self.frequencyTXDoubleSpinBox.setObjectName("frequencyTXDoubleSpinBox")
        self.specialFieldsTabWidget.addTab(self.splitTab, "")
        self.satelliteTab = QtWidgets.QWidget()
        self.satelliteTab.setObjectName("satelliteTab")
        self.layoutWidget2 = QtWidgets.QWidget(parent=self.satelliteTab)
        self.layoutWidget2.setGeometry(QtCore.QRect(20, 20, 173, 52))
        self.layoutWidget2.setObjectName("layoutWidget2")
        self.formLayout_2 = QtWidgets.QFormLayout(self.layoutWidget2)
        self.formLayout_2.setContentsMargins(0, 0, 0, 0)
        self.formLayout_2.setObjectName("formLayout_2")
        self.label_7 = QtWidgets.QLabel(parent=self.layoutWidget2)
        self.label_7.setObjectName("label_7")
        self.formLayout_2.setWidget(0, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_7)
        self.satNameComboBox = QtWidgets.QComboBox(parent=self.layoutWidget2)
        self.satNameComboBox.setEditable(True)
        self.satNameComboBox.setObjectName("satNameComboBox")
        self.formLayout_2.setWidget(0, QtWidgets.QFormLayout.ItemRole.FieldRole, self.satNameComboBox)
        self.label_8 = QtWidgets.QLabel(parent=self.layoutWidget2)
        self.label_8.setObjectName("label_8")
        self.formLayout_2.setWidget(1, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_8)
        self.satModeLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget2)
        self.satModeLineEdit.setObjectName("satModeLineEdit")
        self.formLayout_2.setWidget(1, QtWidgets.QFormLayout.ItemRole.FieldRole, self.satModeLineEdit)
        self.specialFieldsTabWidget.addTab(self.satelliteTab, "")
        self.contestTab = QtWidgets.QWidget()
        self.contestTab.setObjectName("contestTab")
        self.layoutWidget3 = QtWidgets.QWidget(parent=self.contestTab)
        self.layoutWidget3.setGeometry(QtCore.QRect(10, 10, 197, 108))
        self.layoutWidget3.setObjectName("layoutWidget3")
        self.formLayout_4 = QtWidgets.QFormLayout(self.layoutWidget3)
        self.formLayout_4.setContentsMargins(0, 0, 0, 0)
        self.formLayout_4.setObjectName("formLayout_4")
        self.label_29 = QtWidgets.QLabel(parent=self.layoutWidget3)
        self.label_29.setObjectName("label_29")
        self.formLayout_4.setWidget(0, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_29)
        self.contestNameComboBox = QtWidgets.QComboBox(parent=self.layoutWidget3)
        self.contestNameComboBox.setEditable(True)
        self.contestNameComboBox.setObjectName("contestNameComboBox")
        self.formLayout_4.setWidget(0, QtWidgets.QFormLayout.ItemRole.FieldRole, self.contestNameComboBox)
        self.label_30 = QtWidgets.QLabel(parent=self.layoutWidget3)
        self.label_30.setObjectName("label_30")
        self.formLayout_4.setWidget(1, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_30)
        self.arrlSectionLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget3)
        self.arrlSectionLineEdit.setObjectName("arrlSectionLineEdit")
        self.formLayout_4.setWidget(1, QtWidgets.QFormLayout.ItemRole.FieldRole, self.arrlSectionLineEdit)
        self.label_31 = QtWidgets.QLabel(parent=self.layoutWidget3)
        self.label_31.setObjectName("label_31")
        self.formLayout_4.setWidget(2, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_31)
        self.serialRcvLineEdit = QtWidgets.QLineEdit(parent=self.layoutWidget3)
        self.serialRcvLineEdit.setObjectName("serialRcvLineEdit")
        self.formLayout_4.setWidget(2, QtWidgets.QFormLayout.ItemRole.FieldRole, self.serialRcvLineEdit)
        self.label_32 = QtWidgets.QLabel(parent=self.layoutWidget3)
        self.label_32.setObjectName("label_32")
        self.formLayout_4.setWidget(3, QtWidgets.QFormLayout.ItemRole.LabelRole, self.label_32)
        self.serialSentSpinBox = QtWidgets.QSpinBox(parent=self.layoutWidget3)
        self.serialSentSpinBox.setMaximum(99999)
        self.serialSentSpinBox.setObjectName("serialSentSpinBox")
        self.formLayout_4.setWidget(3, QtWidgets.QFormLayout.ItemRole.FieldRole, self.serialSentSpinBox)
        self.specialFieldsTabWidget.addTab(self.contestTab, "")
        self.splitter_2 = QtWidgets.QSplitter(parent=self.groupBox)
        self.splitter_2.setGeometry(QtCore.QRect(8, 110, 381, 22))
        self.splitter_2.setOrientation(QtCore.Qt.Orientation.Horizontal)
        self.splitter_2.setObjectName("splitter_2")
        self.label_4 = QtWidgets.QLabel(parent=self.splitter_2)
        self.label_4.setObjectName("label_4")
        self.modeComboBox = QtWidgets.QComboBox(parent=self.splitter_2)
        self.modeComboBox.setStatusTip("")
        self.modeComboBox.setEditable(True)
        self.modeComboBox.setObjectName("modeComboBox")
        self.label_11 = QtWidgets.QLabel(parent=self.splitter_2)
        self.label_11.setObjectName("label_11")
        self.RSTSendLineEdit = QtWidgets.QLineEdit(parent=self.splitter_2)
        self.RSTSendLineEdit.setObjectName("RSTSendLineEdit")
        self.label_12 = QtWidgets.QLabel(parent=self.splitter_2)
        self.label_12.setObjectName("label_12")
        self.RSTReceivedLineEdit = QtWidgets.QLineEdit(parent=self.splitter_2)
        self.RSTReceivedLineEdit.setObjectName("RSTReceivedLineEdit")
        self.splitter = QtWidgets.QSplitter(parent=self.groupBox)
        self.splitter.setGeometry(QtCore.QRect(10, 30, 374, 22))
        self.splitter.setOrientation(QtCore.Qt.Orientation.Horizontal)
        self.splitter.setObjectName("splitter")
        self.label = QtWidgets.QLabel(parent=self.splitter)
        self.label.setObjectName("label")
        self.theirCallLineEdit = QtWidgets.QLineEdit(parent=self.splitter)
        self.theirCallLineEdit.setObjectName("theirCallLineEdit")
        self.label_2 = QtWidgets.QLabel(parent=self.splitter)
        self.label_2.setObjectName("label_2")
        self.dateEdit = QtWidgets.QDateEdit(parent=self.splitter)
        self.dateEdit.setCalendarPopup(True)
        self.dateEdit.setObjectName("dateEdit")
        self.label_6 = QtWidgets.QLabel(parent=self.splitter)
        self.label_6.setObjectName("label_6")
        self.timeEdit = QtWidgets.QTimeEdit(parent=self.splitter)
        self.timeEdit.setObjectName("timeEdit")
        self.saveQSOButtonBox = QtWidgets.QDialogButtonBox(parent=self.groupBox)
        self.saveQSOButtonBox.setGeometry(QtCore.QRect(330, 250, 151, 24))
        self.saveQSOButtonBox.setStandardButtons(QtWidgets.QDialogButtonBox.StandardButton.Discard|QtWidgets.QDialogButtonBox.StandardButton.Save)
        self.saveQSOButtonBox.setObjectName("saveQSOButtonBox")
        self.commentsPlainTextEdit = QtWidgets.QPlainTextEdit(parent=self.groupBox)
        self.commentsPlainTextEdit.setGeometry(QtCore.QRect(10, 170, 471, 71))
        self.commentsPlainTextEdit.setObjectName("commentsPlainTextEdit")
        self.label_5 = QtWidgets.QLabel(parent=self.groupBox)
        self.label_5.setGeometry(QtCore.QRect(10, 150, 61, 16))
        self.label_5.setObjectName("label_5")
        self.updateButtonBox = QtWidgets.QDialogButtonBox(parent=self.groupBox)
        self.updateButtonBox.setGeometry(QtCore.QRect(10, 250, 156, 24))
        self.updateButtonBox.setStandardButtons(QtWidgets.QDialogButtonBox.StandardButton.NoButton)
        self.updateButtonBox.setObjectName("updateButtonBox")
        self.splitter_4 = QtWidgets.QSplitter(parent=self.groupBox)
        self.splitter_4.setGeometry(QtCore.QRect(10, 70, 381, 22))
        self.splitter_4.setOrientation(QtCore.Qt.Orientation.Horizontal)
        self.splitter_4.setObjectName("splitter_4")
        self.label_3 = QtWidgets.QLabel(parent=self.splitter_4)
        self.label_3.setObjectName("label_3")
        self.bandComboBox = QtWidgets.QComboBox(parent=self.splitter_4)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Policy.MinimumExpanding, QtWidgets.QSizePolicy.Policy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.bandComboBox.sizePolicy().hasHeightForWidth())
        self.bandComboBox.setSizePolicy(sizePolicy)
        self.bandComboBox.setStatusTip("")
        self.bandComboBox.setEditable(True)
        self.bandComboBox.setObjectName("bandComboBox")
        self.label_9 = QtWidgets.QLabel(parent=self.splitter_4)
        self.label_9.setObjectName("label_9")
        self.frequencyDoubleSpinBox = QtWidgets.QDoubleSpinBox(parent=self.splitter_4)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Policy.Maximum, QtWidgets.QSizePolicy.Policy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.frequencyDoubleSpinBox.sizePolicy().hasHeightForWidth())
        self.frequencyDoubleSpinBox.setSizePolicy(sizePolicy)
        self.frequencyDoubleSpinBox.setPrefix("")
        self.frequencyDoubleSpinBox.setDecimals(5)
        self.frequencyDoubleSpinBox.setMaximum(7500000.99)
        self.frequencyDoubleSpinBox.setObjectName("frequencyDoubleSpinBox")
        self.label_33 = QtWidgets.QLabel(parent=self.splitter_4)
        self.label_33.setObjectName("label_33")
        self.powerLineEdit = QtWidgets.QLineEdit(parent=self.splitter_4)
        self.powerLineEdit.setObjectName("powerLineEdit")
        self.logListTableView = QtWidgets.QTableView(parent=self.centralwidget)
        self.logListTableView.setGeometry(QtCore.QRect(20, 40, 811, 231))
        self.logListTableView.setObjectName("logListTableView")
        self.splitter_3 = QtWidgets.QSplitter(parent=self.centralwidget)
        self.splitter_3.setGeometry(QtCore.QRect(450, 10, 367, 22))
        self.splitter_3.setOrientation(QtCore.Qt.Orientation.Horizontal)
        self.splitter_3.setObjectName("splitter_3")
        self.label_14 = QtWidgets.QLabel(parent=self.splitter_3)
        self.label_14.setObjectName("label_14")
        self.localDateTimeEdit = QtWidgets.QDateTimeEdit(parent=self.splitter_3)
        self.localDateTimeEdit.setReadOnly(True)
        self.localDateTimeEdit.setObjectName("localDateTimeEdit")
        self.label_15 = QtWidgets.QLabel(parent=self.splitter_3)
        self.label_15.setObjectName("label_15")
        self.zuluDateTimeEdit = QtWidgets.QDateTimeEdit(parent=self.splitter_3)
        self.zuluDateTimeEdit.setTimeSpec(QtCore.Qt.TimeSpec.UTC)
        self.zuluDateTimeEdit.setObjectName("zuluDateTimeEdit")
        self.groupBox.raise_()
        self.splitter_3.raise_()
        self.searchLineEdit.raise_()
        self.label_13.raise_()
        self.logListTableView.raise_()
        MainWindow.setCentralWidget(self.centralwidget)
        self.menubar = QtWidgets.QMenuBar(parent=MainWindow)
        self.menubar.setGeometry(QtCore.QRect(0, 0, 848, 22))
        self.menubar.setObjectName("menubar")
        self.menu_File = QtWidgets.QMenu(parent=self.menubar)
        self.menu_File.setObjectName("menu_File")
        self.menu_Configure = QtWidgets.QMenu(parent=self.menubar)
        self.menu_Configure.setObjectName("menu_Configure")
        self.menuE_xport = QtWidgets.QMenu(parent=self.menubar)
        self.menuE_xport.setObjectName("menuE_xport")
        self.menuM_y_End = QtWidgets.QMenu(parent=self.menubar)
        self.menuM_y_End.setObjectName("menuM_y_End")
        MainWindow.setMenuBar(self.menubar)
        self.statusbar = QtWidgets.QStatusBar(parent=MainWindow)
        self.statusbar.setObjectName("statusbar")
        MainWindow.setStatusBar(self.statusbar)
        self.toolBar = QtWidgets.QToolBar(parent=MainWindow)
        self.toolBar.setObjectName("toolBar")
        MainWindow.addToolBar(QtCore.Qt.ToolBarArea.TopToolBarArea, self.toolBar)
        self.action_New_Logbook = QtGui.QAction(parent=MainWindow)
        self.action_New_Logbook.setObjectName("action_New_Logbook")
        self.action_Open_Logbook = QtGui.QAction(parent=MainWindow)
        self.action_Open_Logbook.setObjectName("action_Open_Logbook")
        self.action_Save_Logbook = QtGui.QAction(parent=MainWindow)
        self.action_Save_Logbook.setObjectName("action_Save_Logbook")
        self.action_Exit = QtGui.QAction(parent=MainWindow)
        self.action_Exit.setObjectName("action_Exit")
        self.actionE_xport_Logbook = QtGui.QAction(parent=MainWindow)
        self.actionE_xport_Logbook.setObjectName("actionE_xport_Logbook")
        self.action_My_Information = QtGui.QAction(parent=MainWindow)
        self.action_My_Information.setObjectName("action_My_Information")
        self.actionQRZ_Interaction = QtGui.QAction(parent=MainWindow)
        self.actionQRZ_Interaction.setObjectName("actionQRZ_Interaction")
        self.action_ADI_File = QtGui.QAction(parent=MainWindow)
        self.action_ADI_File.setObjectName("action_ADI_File")
        self.action_Cabrillo_Format = QtGui.QAction(parent=MainWindow)
        self.action_Cabrillo_Format.setObjectName("action_Cabrillo_Format")
        self.actionMy_Rig = QtGui.QAction(parent=MainWindow)
        self.actionMy_Rig.setCheckable(True)
        self.actionMy_Rig.setObjectName("actionMy_Rig")
        self.actionThis_is_a_POTA_activation = QtGui.QAction(parent=MainWindow)
        self.actionThis_is_a_POTA_activation.setCheckable(True)
        self.actionThis_is_a_POTA_activation.setObjectName("actionThis_is_a_POTA_activation")
        self.actionImport_A_DI = QtGui.QAction(parent=MainWindow)
        self.actionImport_A_DI.setObjectName("actionImport_A_DI")
        self.actionImport_Ca_brillo = QtGui.QAction(parent=MainWindow)
        self.actionImport_Ca_brillo.setObjectName("actionImport_Ca_brillo")
        self.actionSend_to_QR_Z = QtGui.QAction(parent=MainWindow)
        self.actionSend_to_QR_Z.setObjectName("actionSend_to_QR_Z")
        self.actionAt_a_SOTA_activation = QtGui.QAction(parent=MainWindow)
        self.actionAt_a_SOTA_activation.setCheckable(True)
        self.actionAt_a_SOTA_activation.setObjectName("actionAt_a_SOTA_activation")
        self.actionUI_Behavior = QtGui.QAction(parent=MainWindow)
        self.actionUI_Behavior.setObjectName("actionUI_Behavior")
        self.actionUI_Look_and_Feel = QtGui.QAction(parent=MainWindow)
        self.actionUI_Look_and_Feel.setObjectName("actionUI_Look_and_Feel")
        self.menu_File.addAction(self.action_New_Logbook)
        self.menu_File.addAction(self.action_Open_Logbook)
        self.menu_File.addAction(self.action_Save_Logbook)
        self.menu_File.addAction(self.action_Exit)
        self.menu_Configure.addAction(self.action_My_Information)
        self.menu_Configure.addAction(self.actionQRZ_Interaction)
        self.menu_Configure.addAction(self.actionUI_Behavior)
        self.menu_Configure.addAction(self.actionUI_Look_and_Feel)
        self.menuE_xport.addAction(self.action_ADI_File)
        self.menuE_xport.addAction(self.action_Cabrillo_Format)
        self.menuE_xport.addSeparator()
        self.menuE_xport.addAction(self.actionImport_A_DI)
        self.menuE_xport.addAction(self.actionImport_Ca_brillo)
        self.menuE_xport.addSeparator()
        self.menuE_xport.addAction(self.actionSend_to_QR_Z)
        self.menuM_y_End.addAction(self.actionMy_Rig)
        self.menuM_y_End.addAction(self.actionThis_is_a_POTA_activation)
        self.menuM_y_End.addAction(self.actionAt_a_SOTA_activation)
        self.menubar.addAction(self.menu_File.menuAction())
        self.menubar.addAction(self.menu_Configure.menuAction())
        self.menubar.addAction(self.menuE_xport.menuAction())
        self.menubar.addAction(self.menuM_y_End.menuAction())

        self.retranslateUi(MainWindow)
        self.specialFieldsTabWidget.setCurrentIndex(1)
        QtCore.QMetaObject.connectSlotsByName(MainWindow)
        MainWindow.setTabOrder(self.theirCallLineEdit, self.dateEdit)
        MainWindow.setTabOrder(self.dateEdit, self.timeEdit)
        MainWindow.setTabOrder(self.timeEdit, self.bandComboBox)
        MainWindow.setTabOrder(self.bandComboBox, self.frequencyDoubleSpinBox)
        MainWindow.setTabOrder(self.frequencyDoubleSpinBox, self.powerLineEdit)
        MainWindow.setTabOrder(self.powerLineEdit, self.modeComboBox)
        MainWindow.setTabOrder(self.modeComboBox, self.RSTSendLineEdit)
        MainWindow.setTabOrder(self.RSTSendLineEdit, self.RSTReceivedLineEdit)
        MainWindow.setTabOrder(self.RSTReceivedLineEdit, self.commentsPlainTextEdit)
        MainWindow.setTabOrder(self.commentsPlainTextEdit, self.qsoNameLineEdit)
        MainWindow.setTabOrder(self.qsoNameLineEdit, self.qsoGridLineEdit)
        MainWindow.setTabOrder(self.qsoGridLineEdit, self.qsoAddressLineEdit)
        MainWindow.setTabOrder(self.qsoAddressLineEdit, self.qsoStateLineEdit)
        MainWindow.setTabOrder(self.qsoStateLineEdit, self.latLineEdit)
        MainWindow.setTabOrder(self.latLineEdit, self.lonLineEdit)
        MainWindow.setTabOrder(self.lonLineEdit, self.qsoCountryLineEdit)
        MainWindow.setTabOrder(self.qsoCountryLineEdit, self.theirParkNameLineEdit)
        MainWindow.setTabOrder(self.theirParkNameLineEdit, self.potaStateLineEdit)
        MainWindow.setTabOrder(self.potaStateLineEdit, self.potaGridLineEdit)
        MainWindow.setTabOrder(self.potaGridLineEdit, self.theirParkIDLineEdit)
        MainWindow.setTabOrder(self.theirParkIDLineEdit, self.satModeLineEdit)
        MainWindow.setTabOrder(self.satModeLineEdit, self.searchLineEdit)
        MainWindow.setTabOrder(self.searchLineEdit, self.satNameComboBox)
        MainWindow.setTabOrder(self.satNameComboBox, self.lookupPushButton)
        MainWindow.setTabOrder(self.lookupPushButton, self.potaLatLineEdit)
        MainWindow.setTabOrder(self.potaLatLineEdit, self.potaLonLineEdit)
        MainWindow.setTabOrder(self.potaLonLineEdit, self.frequencyTXDoubleSpinBox)
        MainWindow.setTabOrder(self.frequencyTXDoubleSpinBox, self.contestNameComboBox)
        MainWindow.setTabOrder(self.contestNameComboBox, self.arrlSectionLineEdit)
        MainWindow.setTabOrder(self.arrlSectionLineEdit, self.serialRcvLineEdit)
        MainWindow.setTabOrder(self.serialRcvLineEdit, self.serialSentSpinBox)
        MainWindow.setTabOrder(self.serialSentSpinBox, self.logListTableView)
        MainWindow.setTabOrder(self.logListTableView, self.localDateTimeEdit)
        MainWindow.setTabOrder(self.localDateTimeEdit, self.zuluDateTimeEdit)
        MainWindow.setTabOrder(self.zuluDateTimeEdit, self.specialFieldsTabWidget)

    def retranslateUi(self, MainWindow):
        _translate = QtCore.QCoreApplication.translate
        MainWindow.setWindowTitle(_translate("MainWindow", "MainWindow"))
        self.label_13.setText(_translate("MainWindow", "Search"))
        self.groupBox.setTitle(_translate("MainWindow", "QSO"))
        self.label_20.setText(_translate("MainWindow", "Name"))
        self.qsoNameLineEdit.setToolTip(_translate("MainWindow", "The QS\'s name"))
        self.label_21.setText(_translate("MainWindow", "Grid square"))
        self.qsoGridLineEdit.setToolTip(_translate("MainWindow", "The QSO\'s grid square"))
        self.label_22.setText(_translate("MainWindow", "Address"))
        self.qsoAddressLineEdit.setToolTip(_translate("MainWindow", "QSO\'s address"))
        self.label_23.setText(_translate("MainWindow", "State"))
        self.qsoStateLineEdit.setToolTip(_translate("MainWindow", "QSO\'s state or province"))
        self.label_24.setText(_translate("MainWindow", "Latitude"))
        self.label_25.setText(_translate("MainWindow", "Country"))
        self.qsoCountryLineEdit.setToolTip(_translate("MainWindow", "The country of this QSO"))
        self.latLineEdit.setToolTip(_translate("MainWindow", "QSO\'s latitude in decimal"))
        self.lonLineEdit.setToolTip(_translate("MainWindow", "QSO\'s longitude in decimal"))
        self.label_28.setText(_translate("MainWindow", "Longitude"))
        self.lookupPushButton.setText(_translate("MainWindow", "Lookup"))
        self.specialFieldsTabWidget.setTabText(self.specialFieldsTabWidget.indexOf(self.generalTabl), _translate("MainWindow", "General Info"))
        self.specialFieldsTabWidget.setTabToolTip(self.specialFieldsTabWidget.indexOf(self.generalTabl), _translate("MainWindow", "General Information about your contact"))
        self.label_10.setText(_translate("MainWindow", "Park ID"))
        self.theirParkIDLineEdit.setToolTip(_translate("MainWindow", "Their park ID"))
        self.label_16.setText(_translate("MainWindow", "Park Name"))
        self.theirParkNameLineEdit.setToolTip(_translate("MainWindow", "Their park name"))
        self.label_17.setText(_translate("MainWindow", "State"))
        self.potaStateLineEdit.setToolTip(_translate("MainWindow", "Their park state if different than the QSO\'s state"))
        self.label_18.setText(_translate("MainWindow", "Grid"))
        self.potaGridLineEdit.setToolTip(_translate("MainWindow", "Park\'s gridsquare"))
        self.label_26.setText(_translate("MainWindow", "Latitude"))
        self.potaLatLineEdit.setToolTip(_translate("MainWindow", "Park\'s latitude"))
        self.label_27.setText(_translate("MainWindow", "Longitude"))
        self.potaLonLineEdit.setToolTip(_translate("MainWindow", "Park\'s longitude"))
        self.specialFieldsTabWidget.setTabText(self.specialFieldsTabWidget.indexOf(self.potaTab), _translate("MainWindow", "POTA"))
        self.specialFieldsTabWidget.setTabToolTip(self.specialFieldsTabWidget.indexOf(self.potaTab), _translate("MainWindow", "Fields that help hunting POTA activators"))
        self.label_19.setText(_translate("MainWindow", "TX Frequency"))
        self.frequencyTXDoubleSpinBox.setToolTip(_translate("MainWindow", "No decimals"))
        self.frequencyTXDoubleSpinBox.setSuffix(_translate("MainWindow", "MHz"))
        self.specialFieldsTabWidget.setTabText(self.specialFieldsTabWidget.indexOf(self.splitTab), _translate("MainWindow", "DXing/Split Op"))
        self.specialFieldsTabWidget.setTabToolTip(self.specialFieldsTabWidget.indexOf(self.splitTab), _translate("MainWindow", "Fields for split operation and DX contacts"))
        self.label_7.setText(_translate("MainWindow", "Name"))
        self.label_8.setText(_translate("MainWindow", "Mode"))
        self.specialFieldsTabWidget.setTabText(self.specialFieldsTabWidget.indexOf(self.satelliteTab), _translate("MainWindow", "Satellite"))
        self.specialFieldsTabWidget.setTabToolTip(self.specialFieldsTabWidget.indexOf(self.satelliteTab), _translate("MainWindow", "Fields for satellite operation"))
        self.label_29.setText(_translate("MainWindow", "Name"))
        self.label_30.setText(_translate("MainWindow", "ARRL Sect."))
        self.label_31.setText(_translate("MainWindow", "Serial Rcv"))
        self.label_32.setText(_translate("MainWindow", "Serial Sent"))
        self.specialFieldsTabWidget.setTabText(self.specialFieldsTabWidget.indexOf(self.contestTab), _translate("MainWindow", "Contest"))
        self.specialFieldsTabWidget.setTabToolTip(self.specialFieldsTabWidget.indexOf(self.contestTab), _translate("MainWindow", "Fields useful for contests"))
        self.label_4.setText(_translate("MainWindow", "Mode"))
        self.modeComboBox.setToolTip(_translate("MainWindow", "Enter the mode of operation"))
        self.label_11.setText(_translate("MainWindow", "RST Sent"))
        self.RSTSendLineEdit.setToolTip(_translate("MainWindow", "The RST you sent them"))
        self.RSTSendLineEdit.setText(_translate("MainWindow", "59"))
        self.label_12.setText(_translate("MainWindow", "RST Received"))
        self.RSTReceivedLineEdit.setToolTip(_translate("MainWindow", "The RST you received from them"))
        self.RSTReceivedLineEdit.setText(_translate("MainWindow", "59"))
        self.label.setText(_translate("MainWindow", "Callsign"))
        self.theirCallLineEdit.setToolTip(_translate("MainWindow", "Enter the contact\'s callsign"))
        self.label_2.setText(_translate("MainWindow", "Date"))
        self.dateEdit.setToolTip(_translate("MainWindow", "Enter this qso date"))
        self.label_6.setText(_translate("MainWindow", "Time"))
        self.timeEdit.setToolTip(_translate("MainWindow", "Enter this qso start time"))
        self.saveQSOButtonBox.setToolTip(_translate("MainWindow", "Save or discard this entry"))
        self.commentsPlainTextEdit.setToolTip(_translate("MainWindow", "Any comments?"))
        self.label_5.setText(_translate("MainWindow", "Comment"))
        self.label_3.setText(_translate("MainWindow", "Band"))
        self.bandComboBox.setToolTip(_translate("MainWindow", "Select this QSO\'s band"))
        self.label_9.setText(_translate("MainWindow", "Frequency"))
        self.frequencyDoubleSpinBox.setToolTip(_translate("MainWindow", "Enter the receive frequency in MHz (e.g. 7.125)"))
        self.frequencyDoubleSpinBox.setSuffix(_translate("MainWindow", "MHz"))
        self.label_33.setText(_translate("MainWindow", "Power"))
        self.powerLineEdit.setToolTip(_translate("MainWindow", "Enter the power in Watts"))
        self.label_14.setText(_translate("MainWindow", "Local Time"))
        self.label_15.setText(_translate("MainWindow", "UTC/Zulu"))
        self.menu_File.setTitle(_translate("MainWindow", "&File"))
        self.menu_Configure.setTitle(_translate("MainWindow", "&Configure"))
        self.menuE_xport.setTitle(_translate("MainWindow", "E&xport/Import"))
        self.menuM_y_End.setTitle(_translate("MainWindow", "&I\'m At..."))
        self.toolBar.setWindowTitle(_translate("MainWindow", "toolBar"))
        self.action_New_Logbook.setText(_translate("MainWindow", "&New Logbook"))
        self.action_Open_Logbook.setText(_translate("MainWindow", "&Open Logbook"))
        self.action_Save_Logbook.setText(_translate("MainWindow", "&Save Logbook"))
        self.action_Exit.setText(_translate("MainWindow", "&Exit"))
        self.actionE_xport_Logbook.setText(_translate("MainWindow", "E&xport Logbook"))
        self.action_My_Information.setText(_translate("MainWindow", "&My Information"))
        self.actionQRZ_Interaction.setText(_translate("MainWindow", "QRZ Interaction"))
        self.action_ADI_File.setText(_translate("MainWindow", "Export &ADI File"))
        self.action_Cabrillo_Format.setText(_translate("MainWindow", "Export &Cabrillo Format"))
        self.actionMy_Rig.setText(_translate("MainWindow", "My QTH RIght Now"))
        self.actionThis_is_a_POTA_activation.setText(_translate("MainWindow", "At a &POTA activation"))
        self.actionImport_A_DI.setText(_translate("MainWindow", "Import A&DI"))
        self.actionImport_Ca_brillo.setText(_translate("MainWindow", "Import Ca&brillo"))
        self.actionSend_to_QR_Z.setText(_translate("MainWindow", "Send to QR&Z"))
        self.actionAt_a_SOTA_activation.setText(_translate("MainWindow", "At a SOTA activation"))
        self.actionUI_Behavior.setText(_translate("MainWindow", "UI &Behavior"))
        self.actionUI_Look_and_Feel.setText(_translate("MainWindow", "UI &Look and Feel"))

from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from system_monitor.monitor import SystemMonitor

app = QApplication([])
engine = QQmlApplicationEngine()

monitor = SystemMonitor()
engine.rootContext().setContextProperty("monitorData", monitor)

engine.load("/home/ahmed/.config/quickshell/modules/sysinfo/Monitor.qml")
app.exec()

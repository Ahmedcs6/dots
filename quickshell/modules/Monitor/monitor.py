import psutil
from PySide6.QtCore import QObject, Signal, QTimer, Property


# -------------------------
# CPU + RAM
# -------------------------
def get_cpu_ram():
    cpu_total = psutil.cpu_percent(interval=None)
    cores = psutil.cpu_percent(interval=None, percpu=True)
    ram = psutil.virtual_memory().percent
    return cpu_total, cores, ram

# -------------------------
# GPU Intel iGPU (frequency)
# -------------------------
def get_gpu():
    gpu_usage = 0.0
    gpu_freq = 0.0
    try:
        with open("/sys/class/drm/card1/gt_cur_freq_mhz") as f:
            gpu_freq = float(f.read().strip())
        with open("/sys/class/drm/card1/gt_min_freq_mhz") as f:
            gpu_min = float(f.read().strip())
        with open("/sys/class/drm/card1/gt_max_freq_mhz") as f:
            gpu_max = float(f.read().strip())
        if gpu_max > gpu_min:
            gpu_usage = (gpu_freq - gpu_min) / (gpu_max - gpu_min) * 100
        else:
            gpu_usage = 0.0
    except:
        pass
    return gpu_usage, gpu_freq

class Monitor(QObject):
    dataChanged = Signal()

    def __init__(self):
        super().__init__()
        self._cpu_total = 0
        self._cores = []
        self._ram = 0
        self._gpu_usage = 0
        self._gpu_freq = 0

        self.timer = QTimer()
        self.timer.timeout.connect(self.update_data)
        self.timer.start(500)

    def update_data(self):
        self._cpu_total, self._cores, self._ram = get_cpu_ram()
        self._gpu_usage, self._gpu_freq = get_gpu()
        self.dataChanged.emit()

    @Property(float, notify=dataChanged)
    def cpu_total(self): return self._cpu_total

    @Property('QVariant', notify=dataChanged)
    def cores(self): return self._cores
    
    @Property(float, notify=dataChanged)
    def ram(self): return self._ram
    
    @Property(float, notify=dataChanged)
    def gpu_usage(self): return self._gpu_usage

    @Property(float, notify=dataChanged)
    def gpu_freq(self): return self._gpu_freq

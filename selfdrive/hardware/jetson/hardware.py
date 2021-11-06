import random
import os

from cereal import log
from selfdrive.hardware.base import HardwareBase, ThermalConfig

NetworkType = log.DeviceState.NetworkType
NetworkStrength = log.DeviceState.NetworkStrength


class Jetson(HardwareBase):


  def get_os_version(self):
    return None

  def get_device_type(self):
    return "jetson"

  def get_sound_card_online(self):
    return True

  def reboot(self, reason=None):
    os.system("sudo reboot")

  def uninstall(self):
    pass

  def get_imei(self, slot):
    return "%015d" % random.randint(0, 1 << 32)

  def get_serial(self):
    return "cccccccc"

  def get_subscriber_info(self):
    return ""

  def get_network_type(self):
    return NetworkType.wifi

  def get_sim_info(self):
    return {
      'sim_id': '',
      'mcc_mnc': None,
      'network_type': ["Unknown"],
      'sim_state': ["ABSENT"],
      'data_connected': False
    }

  def get_network_strength(self, network_type):
    return NetworkStrength.unknown

  def get_battery_capacity(self):
    return 100

  def get_battery_status(self):
    return ""

  def get_battery_current(self):
    return 0

  def get_battery_voltage(self):
    return 0

  def get_battery_charging(self):
    return True

  def set_battery_charging(self, on):
    pass

  def get_usb_present(self):
    return True

  def get_current_power_draw(self):
    return 0

  def shutdown(self):
    os.system("sudo poweroff")

  def get_thermal_config(self):
    # 0 = CPU
    # 1 = GPU
    # 2 = AUX
    # 3 = AO (always on rail)
    # 4 = PMIC-Die
    # 5 = Thermal-fan-est
    return ThermalConfig(cpu=((0,), 1000), gpu=((1,), 1000), mem=(4, 1000), bat=(None, 1), ambient=(3, 1000))

  def set_screen_brightness(self, percentage):
    pass

  def set_power_save(self, enabled):
    pass

  def get_gpu_usage_percent(self):
    return 0

  def get_modem_version(self):
    return None

  def initialize_hardware(self):
    pass

  def get_networks(self):
    return None

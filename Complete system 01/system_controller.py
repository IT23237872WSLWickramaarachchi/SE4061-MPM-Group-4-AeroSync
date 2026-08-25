import time
import serial
import subprocess
from pycaw.pycaw import AudioUtilities
import screen_brightness_control as sbc

# Try importing wmi for direct Windows WMI access
try:
    import wmi
    wmi_obj = wmi.WMI(namespace='root\\wmi')
except Exception:
    wmi_obj = None

COM_PORT = 'COM4' 
BAUD_RATE = 115200

# Connect Serial
try:
    ser = serial.Serial(COM_PORT, BAUD_RATE, timeout=1)
    print(f"Connected to ESP32 Transmitter on {COM_PORT}")
    time.sleep(2)
except Exception as e:
    print(f"Error opening serial port: {e}")
    exit()

# Connect Windows Audio
try:
    device = AudioUtilities.GetSpeakers()
    volume_control = device.EndpointVolume
except Exception as e:
    print(f"Error initializing Windows audio device: {e}")
    exit()


def get_windows_brightness():
    """Reliably fetches Windows display brightness using multiple fallback methods."""
    # Method 1: Direct WMI
    if wmi_obj:
        try:
            brightness_instances = wmi_obj.WmiMonitorBrightness()
            if brightness_instances:
                return int(brightness_instances[0].CurrentBrightness)
        except Exception:
            pass

    # Method 2: screen_brightness_control library
    try:
        b = sbc.get_brightness()
        if b and len(b) > 0:
            return int(b[0])
    except Exception:
        pass

    # Method 3: Windows PowerShell WMI query fallback
    try:
        cmd = "powershell (Get-WmiObject -Namespace root/wmi -Class WmiMonitorBrightness).CurrentBrightness"
        output = subprocess.check_output(cmd, shell=True).decode('utf-8').strip()
        if output.isdigit():
            return int(output)
    except Exception:
        pass

    return 50 # Default safe fallback


last_vol = -1
last_bright = -1

print("Monitoring Volume & Brightness... (Press Ctrl+C to stop)")

try:
    while True:
        # 1. Read Volume
        try:
            vol_float = volume_control.GetMasterVolumeLevelScalar()
            current_vol = int(vol_float * 100)
        except Exception:
            current_vol = last_vol if last_vol != -1 else 0

        # 2. Read Brightness
        current_bright = get_windows_brightness()

        # Send update only if either parameter changes
        if current_vol != last_vol or current_bright != last_bright:
            payload = f"V:{current_vol},B:{current_bright}\n"
            ser.write(payload.encode('utf-8'))
            print(f"Sent Payload: {payload.strip()}")
            
            last_vol = current_vol
            last_bright = current_bright

        time.sleep(0.2) # 200ms refresh rate

except KeyboardInterrupt:
    print("\nScript stopped.")
    ser.close()
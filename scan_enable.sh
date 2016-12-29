#!/bin/bash
set -eo pipefail

echo "Watching hci devices..."

while true; do
    devices=$(hciconfig dev | grep hci | awk '{print $1}' | sed -e 's/://')

    for device in $devices
    do
        # Force the device to be up, bluez 5.0 does not remember device power
        # state through restarts
        hciconfig "${device}" up

        scan_enable=$(hcitool -i "${device}" cmd 0x3 0x19|grep -A1 'HCI Event'|tail -1|cut -d\  -f7)
        if [[ "$scan_enable" == '00' ]]; then
            echo "Scan disabled, enabling"
            # Could also use hciconfig hci0 pscan
            success=$(hcitool -i "${device}" cmd 0x3 0x1a 0x2|grep -A1 'HCI Event'|tail -1|cut -d\  -f6)
            if [[ "$success" != '00' ]]; then
                echo "Scan enable failed"
                break
            fi
            echo "Scan now enabled for ${device}"
        fi
    done

    sleep 1
done

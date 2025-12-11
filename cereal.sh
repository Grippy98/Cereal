#!/bin/bash


# Cereal - Serial device terminal manager
# This script detects serial devices and spawns screen sessions at 115200 baud

set -euo pipefail
echo ""
echo "Cereal - Serial device manager"
echo""
echo "     o8Oo./"
echo " ._o8o8o8Oo_."
echo "  \========/"
echo "   \------/ "
echo "=============================="
echo ""


# Get initial list of serial devices
initial_devices=()
while IFS= read -r -d '' device; do
    initial_devices+=("$device")
done < <(find /dev -name "tty*" -print0 2>/dev/null | sort -z)

# Display initial device count
echo "Found ${#initial_devices[@]} serial devices"

# Prompt user to plug in new devices
echo ""
echo "Please plug in your serial devices now... (then press Enter)"
read -r

# Get list of devices after user intervention
final_devices=()
while IFS= read -r -d '' device; do
    final_devices+=("$device")
done < <(find /dev -name "tty*" -print0 2>/dev/null | sort -z)

# Find new devices (devices that were not in the initial list)
new_devices=()
for device in "${final_devices[@]}"; do
    is_new=true
    for initial_device in "${initial_devices[@]}"; do
        if [ "$device" = "$initial_device" ]; then
            is_new=false
            break
        fi
    done
    if [ "$is_new" = true ]; then
        new_devices+=("$device")
    fi
done

# Check if any new devices were found
if [ ${#new_devices[@]} -eq 0 ]; then
    echo ""
    echo "No new serial devices detected."

    # Look for existing USB serial devices
    existing_usb_devices=()
    while IFS= read -r -d '' device; do
        existing_usb_devices+=("$device")
    done < <(find /dev -name "tty.usbserial-*" -print0 2>/dev/null | sort -z)

    if [ ${#existing_usb_devices[@]} -gt 0 ]; then
        echo ""
        echo "However, found ${#existing_usb_devices[@]} existing USB serial device(s)."

        # If only one device, use it automatically
        if [ ${#existing_usb_devices[@]} -eq 1 ]; then
            echo ""
            echo "Connecting to: ${existing_usb_devices[0]}"
            new_devices=("${existing_usb_devices[@]}")
        else
            # Let user choose which device(s)
            echo ""
            echo "Which device(s) would you like to open?"
            echo "Options:"
            echo "0) Open all devices"

            for i in "${!existing_usb_devices[@]}"; do
                echo "$((i+1))) ${existing_usb_devices[$i]}"
            done

            read -p "Enter your choice (0 or 1-${#existing_usb_devices[@]}, or q to quit): " choice

            if [ "$choice" = "0" ]; then
                new_devices=("${existing_usb_devices[@]}")
            elif [[ "$choice" =~ ^[Qq]$ ]]; then
                echo "Exiting."
                exit 0
            elif [ "$choice" -ge 1 ] && [ "$choice" -le "${#existing_usb_devices[@]}" ]; then
                new_devices=("${existing_usb_devices[$((choice-1))]}")
            else
                echo "Invalid choice. Exiting."
                exit 1
            fi
        fi
    else
        exit 1
    fi
fi

echo ""
echo "Detected ${#new_devices[@]} new serial device(s):"

# Show basename of new devices
for device in "${new_devices[@]}"; do
    basename "$device"
done

# If only one new device, automatically open it without prompting
if [ ${#new_devices[@]} -eq 1 ]; then
    device="${new_devices[0]}"
    echo ""
    echo "Opening $device at 115200 baud..."
    # Open in a new terminal window/tab - for macOS
    if command -v osascript &> /dev/null; then
        # For macOS - create new terminal window with screen session
        # First check permissions
        if [ ! -r "$device" ] || [ ! -w "$device" ]; then
            echo "ERROR: No read/write permission for $device"
            echo "Run: sudo chmod 666 $device"
            echo "Or run this script with: sudo $0"
            exit 1
        fi
        osascript -e "tell application \"Terminal\" to do script \"screen $device 115200\"" &
    elif command -v gnome-terminal &> /dev/null; then
        # For Linux - GNOME
        gnome-terminal -- bash -c "screen $device 115200; exec bash" &
    elif command -v xterm &> /dev/null; then
        # For Linux - XTerm
        xterm -e "screen $device 115200" &
    else
        # Fallback - just run screen in background (may not work properly)
        echo "WARNING: No suitable terminal emulator found. Running screen directly."
        screen "$device" 115200 &
    fi
else
    # If multiple devices, prompt user for selection
    echo ""
    echo "Which device(s) would you like to open?"
    echo "Options:"
    echo "0) Open all new devices"
    
    # Show options for each available device
    for i in "${!new_devices[@]}"; do
        echo "$((i+1))) ${new_devices[$i]}"
    done

    read -p "Enter your choice (0 or 1-$(( ${#new_devices[@]} ))): " choice

    if [ "$choice" = "0" ]; then
        # Open all new devices
        echo ""
        echo "Opening all new devices..."
        for device in "${new_devices[@]}"; do
            echo "Opening $device at 115200 baud..."
            # Open in a new terminal window/tab - for macOS
            if command -v osascript &> /dev/null; then
                # For macOS - create new terminal window with screen session
                osascript -e "tell application \"Terminal\" to do script \"screen $device 115200\"" &
            elif command -v gnome-terminal &> /dev/null; then
                # For Linux - GNOME
                gnome-terminal -- bash -c "screen $device 115200; exec bash" &
            elif command -v xterm &> /dev/null; then
                # For Linux - XTerm
                xterm -e "screen $device 115200" &
            else
                # Fallback - just run screen in background (may not work properly)
                echo "WARNING: No suitable terminal emulator found. Running screen directly."
                screen "$device" 115200 &
            fi
        done
    elif [ "$choice" -ge 1 ] && [ "$choice" -le "${#new_devices[@]}" ]; then
        # Validate and open selected device
        if [ "$choice" -ge 1 ] && [ "$choice" -le "${#new_devices[@]}" ]; then
            device="${new_devices[$((choice-1))]}"
            echo ""
            echo "Opening $device at 115200 baud..."
            if command -v osascript &> /dev/null; then
                # For macOS - create new terminal window with screen session
                osascript -e "tell application \"Terminal\" to do script \"screen $device 115200\"" &
            elif command -v gnome-terminal &> /dev/null; then
                # For Linux - GNOME
                gnome-terminal -- bash -c "screen $device 115200; exec bash" &
            elif command -v xterm &> /dev/null; then
                # For Linux - XTerm
                xterm -e "screen $device 115200" &
            else
                # Fallback - just run screen in background (may not work properly)
                echo "WARNING: No suitable terminal emulator found. Running screen directly."
                screen "$device" 115200 &
            fi
        else
            echo "Invalid device number: $choice"
        fi
    else
        echo "Invalid choice. Exiting."
        exit 1
    fi
fi

echo ""
echo "Done."

#!/bin/bash

# Cereal - Serial device terminal manager
# This script detects serial devices and spawns screen sessions at 115200 baud

set -euo pipefail

echo "Cereal - Serial device manager"
echo "=============================="
echo ""

# Get initial list of serial devices
initial_devices=()
while IFS= read -r -d '' device; do
    initial_devices+=("$device")
done < <(find /dev -name "tty*" -print0 2>/dev/null | sort -z)

# Display count of initial devices (but not the actual device names)
echo "Found ${#initial_devices[@]} serial devices"

# Prompt user to plug in new devices
echo ""
echo "Please plug in your serial devices now..."
echo "Press Enter when you're done plugging in devices"
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
    exit 1
fi

echo ""
echo "Detected ${#new_devices[@]} new serial device(s):"

# Show only the basename of new devices (not full paths) - this is what we want per requirements
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
    echo "1) All devices"
    echo "2) Specific device"

    read -p "Enter your choice (1 or 2): " choice

    if [ "$choice" = "1" ]; then
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
    elif [ "$choice" = "2" ]; then
        # Allow user to select specific device(s)
        echo ""
        echo "Available devices:"
        for i in "${!new_devices[@]}"; do
            echo "$((i+1))) ${new_devices[$i]}"
        done
        
        read -p "Enter device numbers separated by spaces (e.g., 1 3): " selected_indices
        
        # Validate and open selected devices
        for index in $selected_indices; do
            if [ "$index" -ge 1 ] && [ "$index" -le "${#new_devices[@]}" ]; then
                device="${new_devices[$((index-1))]}"
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
                echo "Invalid device number: $index"
            fi
        done
    else
        echo "Invalid choice. Exiting."
        exit 1
    fi
fi

echo ""
echo "Done."

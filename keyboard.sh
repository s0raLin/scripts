#!/usr/bin/env bash

# Copyright 2025 Amine Hassane

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

SERVICE="org.kde.KWin"
DBUS_PATH="/org/kde/KWin/InputDevice"
INTERFACE="org.kde.KWin.InputDevice"
METHOD_GET="org.freedesktop.DBus.Properties.Get"
METHOD_SET="org.freedesktop.DBus.Properties.Set"

declare -A devices=(
    ["AT Translated Set 2 keyboard"]=''
)

find_devices() {
    local DM_INTERFACE="org.kde.KWin.InputDeviceManager"
    local DM_PROPERTY="devicesSysNames"

    for sysname in $(qdbus6 "$SERVICE" "$DBUS_PATH" "$METHOD_GET" "$DM_INTERFACE" "$DM_PROPERTY"); do
        name=$(qdbus6 "$SERVICE" "${DBUS_PATH}/${sysname}" "$METHOD_GET" "$INTERFACE" name)

        for device in "${!devices[@]}"; do
            if [ "$name" == "$device" ]; then
                devices["$device"]="$sysname"
            fi
        done
    done
}

check_devices() {
    local return_code=0
    for device in "${!devices[@]}"; do
        sysname=${devices["$device"]}
        if [ -z "$device" ]; then
            echo "Failed to find device ($device)"
            return_code=1
        fi
    done
    return "$return_code"
}

get_device_status() {
    qdbus6 "$SERVICE" "${DBUS_PATH}/$1" "$METHOD_GET" "$INTERFACE" "enabled"
}

set_device_status() {
    qdbus6 "$SERVICE" "${DBUS_PATH}/$1" "$METHOD_SET" "$INTERFACE" "enabled" "$2"
}

toggle_device() {
    status=$(get_device_status "$1")
    status=$([[ "$status" == "false" ]] && echo true || echo false)
    set_device_status "$1" "$status"
}

find_devices
if ! check_devices; then
    exit 1
fi

for device in "${!devices[@]}"; do
    sysname=${devices["$device"]}
    case "$1" in
        "enable") set_device_status "$sysname" true ;;
        "disable") set_device_status "$sysname" false ;;
        "toggle") toggle_device "$sysname" ;;
        "status") echo "$device: $(get_device_status "$sysname" )"
    esac
done

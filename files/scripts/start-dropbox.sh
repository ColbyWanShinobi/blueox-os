#! /bin/bash

# Ensure that org.kde.StatusNotifierWatcher is running. If not, sleep 6 times for 10 seconds each time and then finally fail
if ! dbus-send --session --type=method_call --print-reply --dest=org.freedesktop.DBus \
    /org/freedesktop/DBus org.freedesktop.DBus.NameHasOwner string:"org.kde.StatusNotifierWatcher" | grep -q boolean\ true; then
    for i in {1..6}; do
        sleep 10
        if dbus-send --session --type=method_call --print-reply --dest=org.freedesktop.DBus \
            /org/freedesktop/DBus org.freedesktop.DBus.NameHasOwner string:"org.kde.StatusNotifierWatcher" | grep -q boolean\ true; then
            break
        fi
    done
fi

# Start Dropbox
dropbox start

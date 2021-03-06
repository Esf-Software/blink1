#!/bin/bash
# Change Blink(1)'s colour based on Pidgin status.
# Copyright (C) 2013 Evan Lowry <lowry.e@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

BLINK1=`which blink1-tool`

# Pidgin's DBUS settings
DBUS_INTERFACE="im.pidgin.purple.PurpleInterface"
DBUS_SERVICE="im.pidgin.purple.PurpleService"
DBUS_PATH="/im/pidgin/purple/PurpleObject"

# Pidgin's Status Type IDs
PIDGIN_STATUS_TYPE_OFFLINE=1
PIDGIN_STATUS_TYPE_AVAILABLE=2
PIDGIN_STATUS_TYPE_UNAVAILABLE=3
PIDGIN_STATUS_TYPE_INVISIBLE=4
PIDGIN_STATUS_TYPE_AWAY=5

# Set colours
STATUS_AVAILABLE=0,255,0     # Green
STATUS_AWAY=255,200,0        # Yellow
STATUS_UNAVAILABLE=255,0,0   # Red
STATUS_INVISIBLE=255,255,255 # White
STATUS_OFFLINE=0,0,0         # Black (Off)

# On exit, shut off the blink1
trap "{ $BLINK1 --off &> /dev/null; exit $?; }" SIGINT SIGTERM

# Daemon
dbus-monitor --profile \
    "type='signal',interface='$DBUS_INTERFACE',member='SavedstatusChanged'" \
    "type='signal',interface='$DBUS_INTERFACE',member='Quitting'" \
    "type='signal',interface='$DBUS_INTERFACE',member='SignedOn'" | 
while read -r line; do
    
    message=`echo "$line" | rev | cut -d$'\t' -f1 | rev`

    # Turn off the blink1 if pidgin is closed
    if [ "$message" == 'Quitting' ]; then
        $BLINK1 --off &> /dev/null
        continue
    fi

    # Get status text
    STATUS=`dbus-send --print-reply=literal --dest=$DBUS_SERVICE $DBUS_PATH $DBUS_INTERFACE.PurpleSavedstatusGetCurrent`
    STATUS_ID=`dbus-send --print-reply=literal --dest=$DBUS_SERVICE $DBUS_PATH $DBUS_INTERFACE.PurpleSavedstatusGetCurrent | cut -d ' ' -f5`
    STATUS_TYPE=`dbus-send --print-reply=literal --dest=$DBUS_SERVICE $DBUS_PATH $DBUS_INTERFACE.PurpleSavedstatusGetType int32:$STATUS_ID | cut -d ' ' -f5`

    #Handle changing the colour
    case "$STATUS_TYPE" in
        "$PIDGIN_STATUS_TYPE_AVAILABLE")
            $BLINK1 --rgb $STATUS_AVAILABLE &> /dev/null;;
        "$PIDGIN_STATUS_TYPE_AWAY")
            $BLINK1 --rgb $STATUS_AWAY &> /dev/null;;
        "$PIDGIN_STATUS_TYPE_UNAVAILABLE")
            $BLINK1 --rgb $STATUS_UNAVAILABLE &> /dev/null;;
        "$PIDGIN_STATUS_TYPE_INVISIBLE")
            $BLINK1 --rgb $STATUS_INVISIBLE &> /dev/null;;
        "$PIDGIN_STATUS_TYPE_OFFLINE")
            $BLINK1 --rgb $STATUS_OFFLINE &> /dev/null;;
    esac
done

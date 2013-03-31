#!/bin/sh
ENV=/mnt/us/.bashrc
LOGFILE="/var/tmp/commands"
LOGFUNCTION="-logfn" 
DONULL="/dev/null"
REDIRECT=">"


#To enable logging
#DONULL="" 
#LOGFUNCTION=""


# TO NERF REDIRECTION
#REDIRECT=""
#LOGFILE=""

BINARY="/mnt/us/extensions/vague`uname -m`/bin/pocketsphinx_continuous"
LD="LD_LIBRARY_PATH=/mnt/us/extensions/vague`uname -m`/lib:$LD_LIBRARY_PATH"
MODEL="/mnt/us/extensions/vague`uname -m`/share/pocketsphinx/model/gui.lm"
DICT="/mnt/us/extensions/vague`uname -m`/share/pocketsphinx/model/gui.dic"
BB="/mnt/us/extensions/system/bin/busybox"

#nice "-n" "8" "$BINARY" -lm "$MODEL" -dict "$DICT" "$LOGFUNCTION" "$DONULL" "$REDIRECT" "$LOGFILE"

nice "-n" "8" "$BINARY" -lm "$MODEL" -dict "$DICT" "$LOGFUNCTION" "$DONULL" > "$LOGFILE"

# "$BINARY" -lm "$MODEL" -dict "$DICT" "$LOGFUNCTION" "$DONULL" > "$LOGFILE"


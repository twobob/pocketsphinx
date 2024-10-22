#!/bin/sh
# MAKE PUTTING THINGS IN THE STATUS BAR SANELY BEARABLE
QUOT='{"titleBar":{"clientParams":{"secondary":"'
SECOND='","useDefaultPrimary":false}}}'"'"

# SETUP SOME PATHS
LOGFILE="/var/tmp/commands"
SETPROP="/usr/bin/lipc-set-prop"
EXTDIR="/mnt/us/extensions/vague`uname -m`"
BINARY=$EXTDIR"/bin/pocketsphinx_continuous"
LOOPER=$EXTDIR"/looper.sh"
BB="/mnt/us/extensions/system/bin/busybox"

# DETERMINE MACHINE TYPE 
ARCH="`uname -m`"

# NOW SETUP A MACHINE SPECIFIC BIN PATH
SYSTEMBIN="/mnt/us/extensions/system/bin/$ARCH"

# SETUP A QUICK KILL COMMAND
SHUSH="killall -9 pocketsphinx_continuous"

# LONGEST SENTENCE (like "I[ ]AM[ ]A[ ]SENTENCE[ ]")
SPACEMAX="8"

# CLEAR DOWN ANY OLD JUNK
killall -9 looper.sh
$SHUSH
echo -n "" > /var/tmp/talk
echo -n "" >/var/tmp/command
echo -n "" >/var/tmp/wordmatch
WORDMATCH="FALSE"  # CREATE DEFAULT NON-MATCH


# SETUP STARTUP ANNOUNCEMENT  ==========================================================
STARTUPANNOUNCE="This is Vague. The Talking Gooey"
# YOU CAN EDIT THIS TO YOUR DESIRES ====================================================

"$SETPROP" -s com.lab126.pillow configureChrome -s "$QUOT""$STARTUPANNOUNCE""$SECOND" 

# FORCE 1st loop
/mnt/us/extensions/flite/flite " $STARTUPANNOUNCE ." 
sleep 2


# LETS GET THIS PARTY STARTED
"$SETPROP" -s com.lab126.pillow configureChrome -s "$QUOT""Initialising.""$SECOND"

# STARTUP OUR FIRST BACKGROUND LISTENER
"$LOOPER" &

# START LOOP
while :; 
do usleep 50000
OUT=$(tail -n1 "$LOGFILE"  | tr '\n' ' ' )

#echo "out is $OUT"

# Work our way back down the list in reverse.
"$SYSTEMBIN"/truncate -s -"$(tail -n1 $LOGFILE | wc -c)" "$LOGFILE"


SPACECOUNT=$(echo "$OUT" | grep -o " " | wc -l)
#echo -n $OUT

TEST=$( echo "$OUT" | tr -d ' '| tr -d '.')
#echo "TEST is --(""$TEST"")--"
#echo "COMMAND PARSED WAS --(""$OUT"")--"

# DO WE HAVE A COMMAND (remove whitespace for the test)
if [ -n "$TEST" ]; then

# IS A JUMBLE OF WORDS OR LESS THAN 3 WORDS
if [ ! "$SPACECOUNT" -le "$SPACEMAX" ]; then
echo  "Space count $SPACECOUNT Not Less than Maximum spaces allowed $SPACEMAX"
"$SETPROP" -s com.lab126.pillow configureChrome -s "$QUOT""Phrase too long... Take it slow""$SECOND"
OUT=""
/usr/bin/aplay "$EXTDIR""/usr/on1.wav"
fi

echo -n " $OUT ." > /var/tmp/talk 
echo -n "$OUT" > /var/tmp/command

VAR=$(cat /var/tmp/talk)
TRIMVAR=$(echo "$OUT" | sed 's/ *$//g')

# IS IT A VALID NON-SPACE ONLY VARIABLE?
if [ -n "$TRIMVAR"  ]; then

# RUN POSSIBLE ACTION MATCHING

###################################################################################################
######  YOU PROBABLY WANT TO ADD TO THESE COMMANDS WITH YOUR OWN

echo "Case was --(""$TRIMVAR"")--"
echo -n "TRUE" > /var/tmp/wordmatch

		case $TRIMVAR in
			
		"READY") ( echo -n "STARTUP" > /var/tmp/wordmatch ) ;;
		
		# BACK TO THE HOME PAGE...
		"HOME"|"GO HOME"|"CLOSE"|"CLOSE THAT"|"CLOSE IT"|"KILL IT"|"KILL THAT"|"KILL"|"HOME SCREEN")\
				( "$SETPROP" -s com.lab126.appmgrd start 'app://com.lab126.booklet.home'; killall runit.sh; killall -9 kterm ) ;;
		
		# NOT IMPLEMENTED YET...
		#"NEXT PAGE"|"PAGE FORWARD"|"FORWARD"|"PAGE RIGHT")\
		#		(  "$SETPROP" -s com.lab126.appmgrd start 'app://com.lab126.booklet.home' ) ;;
		
		# EXAMPLE NATIVE APPLICATION LAUNCH
		"BROWSER"|"WEB BROWSER"|"W_W_W"|"WORLD WIDE WEB"|"WEB")\
				( "$SETPROP" -s com.lab126.appmgrd start 'app://com.lab126.browser' ) ;;
		
		# EXAMPLE ALTERNATE NATIVE APPLICATION LAUNCH
		"OPEN STORE"|"AMAZON STORE"|"OPEN AMAZON STORE"|"BUY BOOKS"|"OPEN AMAZON BOOK STORE")\
				( "$SETPROP" -s com.lab126.appmgrd start 'app://com.lab126.store' ) ;;
		
		# EXAMPLE KINDLET LAUNCH
		"RUN COOL"|"OPEN COOL"|"SELECT COOL")\
				( echo -n "KINDLET" > /var/tmp/wordmatch  ) ;;  # They only have 5 seconds to start up so lets really free up resources
		
		# EXAMPLE BACKGROUNDED GTK APPLICATION
		"RUN KAY TERM"|"OPEN KAY TERM"|"KAY TERM")\
				(  /mnt/us/extensions/kterm/bin/runit.sh & sleep 2;   ) ;;  # This might need a moment or two...
		
		# EXAMPLE BACKGROUND SHELL TASK
		"OPEN NETWORKING"|"RUN NETWORKING"|"U_S_B NETWORKING"|"RUN U_S_B NETWORKING"|"NETWORK"|"NETWORKING"|"RUN NETWORK")\
				( /mnt/us/usbnet/bin/usbnetwork ) ;;
		
		# EXAMPLE LIPC CALL
		"SCREEN SAVER"|"POWER OFF"|"POWER DOWN")\
				( "$SETPROP" -i com.lab126.powerd preventScreenSaver 0; /usr/bin/powerd_test -p ) ;;
		
		# EXAMPLE STATEFUL CONTROL
		"KILL SCREEN SAVER")\
				( "$SETPROP" -i com.lab126.powerd preventScreenSaver 1;  ) ;;
		
		# EXAMPLE OTHER STATEFUL CONTROL... NOT YET IMPLEMENTED
		#"KILL SOMETHING ELSE")\
		#		( "$SETPROP" -i com.lab126.powerd preventScreenSaver 1;  ) ;;
		
		# CLOSE THE APPLICATION
		"SHUT DOWN")\
				( echo -n "QUIT" > /var/tmp/wordmatch ) ;;
		
		*) ( echo -n "FALSE" > /var/tmp/wordmatch ; echo "Case was $OUT is not processed" )  ;;
		esac

#################################################################################################################
## EVERYTHING BELOW HERE YOU PROBABLY DO NOT NEED TO CHANGE

# NOW WE WILL BREAK OUT OF CASE MATCHING TO DO SECONDARY TASKS...
# YEAH YEAH some of this could be cased. - EDIT: Now it is.

WORDMATCH=$( cat /var/tmp/wordmatch )
echo "Words found as command Match = $WORDMATCH"


		if [ "$WORDMATCH" == "QUIT" ] ; then
		$SHUSH
		/mnt/us/extensions/flite/flite " Goodbye."
		# EXIT THE APPLICATION
		
		"$SETPROP" -s com.lab126.pillow configureChrome -s "$QUOT""Goodbye""$SECOND" 
		exit 
		fi

		case $WORDMATCH in
		
		'KINDLET' ) (  $SHUSH
		"$SETPROP" -s com.lab126.pillow configureChrome -s "$QUOT""STARTING KUAL!""$SECOND"
		usleep 30000;
		"$SETPROP" com.lab126.appmgrd start "app://com.lab126.booklet.kindlet/mnt/us/documents/KindleLauncher-2.0.azw2"
		sleep 5
		
		# Announce Recognised Words
		/mnt/us/extensions/flite/flite " Cool has been started."
		sleep 1
		
		# RESTART OUR BACKGROUND LISTENER
		"$LOOPER" &		
		
		
		) ;;
		
		'TRUE' ) (
		
		# shut down the listener
		$SHUSH
		usleep 10000
		
			# IS THIS A HIGHER DEVICE?
			if [ "$ARCH" == "armv7l" ] ; then
			lipc-set-prop com.lab126.pillow configureChrome -s "$QUOT""$OUT.""$SECOND"  
			fi
		
		#echo "WORDS ARE  `cat /var/tmp/talk`"
		# Announce Recognised Words
		/mnt/us/extensions/flite/flite -f /var/tmp/talk &
		sleep 1
		
		# RESTART OUR BACKGROUND LISTENER
		"$LOOPER" &
		
		) ;;
		
		'STARTUP' ) (
			
			echo "READY!!"
			# IS THIS A HIGHER DEVICE?
			if [ "$ARCH" == "armv7l" ] ; then
			"$SETPROP" -s com.lab126.pillow configureChrome -s "$QUOT""Now Listening.""$SECOND"
			fi
		
		) ;;
		
		  * )  (
		  
		echo "NO MATCH was --(""$TRIMVAR"")--"
		"$SETPROP" -s com.lab126.pillow configureChrome -s "$QUOT""Phrase not recognised.""$SECOND"
		/usr/bin/aplay "$EXTDIR""/usr/on3.wav"  
		  
		  )  ;; # no-op ; 
		esac  
		
# END IF VALID PHRASE test
sleep 2
fi

# TIDY UP AGAIN ?
echo -n "" > /var/tmp/talk
echo -n "" > /var/tmp/command
echo -n "" > "$LOGFILE" 

fi
done



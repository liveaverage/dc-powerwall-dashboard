#!/bin/bash

# Create/validate cookie for Powerwall API Auth

export POWERWALL_HOST=powerwall
export POWERWALLIP=powerwall                   # This is your Powerwall IP or DNS Name -- we force a host entry to 'powerwall' so static is fine
export PASSWORD=${POWERWALL_PASS}            # Login to the Powerwall UI and Set this password - follow the on-screen instructions
export USERNAME=customer
export EMAIL=tyler@paperstreetsoap.com       # Set this to whatever you want, it's not actually used in the login process; I suspect Tesla will collect this eventually
export COOKIE=/tmp/cookie/PWcookie.txt     
export TOKEN=/tmp/cookie/PWtoken.txt

#echo "Username: $USERNAME Password: $PASSWORD Email: $EMAIL"
#curl -s -k -c $COOKIE -X POST -H "Content-Type: application/json" -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\", \"email\":\"$EMAIL\"}" "https://${POWERWALL_HOST}/api/login/Basic"

######################### START COOKIE AUTH FUNCTIONS #########################
###############################################################################

# Create a valid Cookie
create_cookie () {
	# Delete the old cookie if it exists
	if [ -f $COOKIE ] || [ -f $TOKEN ]; then 
		rm -f $COOKIE $TOKEN
	fi
	
	# Login and Create new cookie
	curl -s -k -c $COOKIE -X POST -H "Content-Type: application/json" -d "{\"username\":\"customer\",\"password\":\"$PASSWORD\", \"email\":\"$EMAIL\"}" "https://${POWERWALL_HOST}/api/login/Basic"  | sed -e 's/.*token":"\(.*\)","provider".*/\1/' > $TOKEN

	# If Login fails, then throw error and exit
	if [ $? -eq 200 ]; then
		echo "Login failed"
		exit;
	fi

    # Update telegraf config based on existing variables
    COOKIE_REC=`grep UserRecord ${COOKIE} | awk '{print($7)}'`
    COOKIE_AUTH=`grep AuthCookie ${COOKIE} | awk '{print($7)}'`

    # User .src as template, then perform second sed update in-place:
    sed "s/AuthCookie=[^;]*/AuthCookie=${COOKIE_AUTH}/g" /etc/telegraf/telegraf.conf.src > /etc/telegraf/telegraf.conf
    sed -i "s/UserRecord=[^\"]*/UserRecord=${COOKIE_REC}/g" /etc/telegraf/telegraf.conf

    # Send SIGHUP to telegraf for configuration reload: https://www.influxdata.com/blog/continuous-deployment-of-telegraf-configurations/
    if pgrep telegraf; then pkill -1 telegraf; fi
}

# Check for a valid cookie
valid_cookie () {

	# if cookie doesnt exist, then login and create the cookie
	if [ ! -f $COOKIE ] || [ ! -f $TOKEN ]; then
  		# Cookie not present. Creating cookie.
		create_cookie
	fi

	# If the cookie is older than one day old, refresh the cookie
	# Collect both times in seconds-since-the-epoch
	AGE_4H=$(date -d 'now - 4 hours' +%s)
	FILE_TIME=$(date -r "$COOKIE" +%s)

	if [ "$FILE_TIME" -le "$AGE_4H" ]; then
		#The cookie is older than 4h; get a new cookie
		create_cookie
	fi
}

#######################################################
# Main
#######################################################

# Clear initial cookie/token data on entrypoint
rm -f /tmp/cookie/PW*

# Check for a valid cookie or login and create one
valid_cookie


######################### END COOKIE AUTH FUNCTIONS ###########################
###############################################################################

# Start telegraf:
/usr/bin/telegraf --config /etc/telegraf/telegraf.conf --config-directory /etc/telegraf/telegraf.d &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start telegraf: $status"
  exit $status
fi

while sleep 60; do
    ps aux |grep telegraf |grep -q -v grep
    PROCESS_2_STATUS=$?
    # If the greps above find anything, they exit with 0 status
    # If they are not both 0, then something is wrong
    if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 ]; then
        echo "One of the processes has already exited."
        exit 1
    fi

    # Check for a valid cookie or login and create one
    valid_cookie

done
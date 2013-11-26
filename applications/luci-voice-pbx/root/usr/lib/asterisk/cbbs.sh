#!/bin/sh

#######################################################
# CallBackBusySubscriber
#
# Creates a callfile in /var/spool/asterisk/outgoing
# that will call a number repetedly until answered.
# On answer, will handle as an incoming call to a
# specified phone.
#
# NOTE: that this feature does not work like ordinary
# (PSTN) CBBS, because in this case, the called party
# must answer first, and caller will then be notified
# about the answer like a normal incoming call. This
# is opposite to the way ordinary CBBS works, where
# caller will be notified first.
#
# Usage:
# cbbs.sh SIPChannel Number CallbackLine MaxRetries RetryTime WaitTime
#
# Example:
# ./cbbs.sh peer-sipall 07012345678 BRCM/0 5 300 45
#####################################################

#Create temporary file
tempfile=$(mktemp)

#Outgoing call settings
echo "Channel: SIP/$1/$2" >> $tempfile
echo "MaxRetries: $4" >> $tempfile
echo "RetryTime: $5" >> $tempfile
echo "WaitTime: $6" >> $tempfile
echo "Set: BRCMLINE=$3" >> $tempfile

#On answer
echo "Context: cbbs" >> $tempfile
echo "Extension: s" >> $tempfile
echo "Priority: 1" >> $tempfile

#Place callfile
mv $tempfile /var/spool/asterisk/outgoing/$$.call


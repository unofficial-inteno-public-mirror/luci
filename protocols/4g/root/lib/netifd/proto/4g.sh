#!/bin/sh
INCLUDE_ONLY=1

. /lib/functions.sh
. ../netifd-proto.sh
init_proto "$@"

proto_4g_init_config() {
	proto_config_add_string "service"
	proto_config_add_string "cdcdev"
	proto_config_add_string "ttydev"
	proto_config_add_string "ipaddr"
	proto_config_add_string "netmask"
	proto_config_add_string "hostname"
	proto_config_add_string "clientid"
	proto_config_add_string "vendorid"
	proto_config_add_boolean "broadcast"
	proto_config_add_string "reqopts"
	proto_config_add_string "apn"
	proto_config_add_string "username"
	proto_config_add_string "password"
	proto_config_add_boolean "lte_apn_use"
	proto_config_add_string "lte_apn"
	proto_config_add_string "lte_username"
	proto_config_add_string "lte_password"
	proto_config_add_string "pincode"
	proto_config_add_string "technology"
	proto_config_add_string "auto"
}

proto_4g_setup() {
	local config="$1"
	local iface="$2"
	local service cdcdev ttydev ipaddr hostname clientid vendorid broadcast reqopts apn username password pincode auto lte_apn_use lte_apn lte_username lte_password
	json_get_vars service cdcdev ttydev ipaddr hostname clientid vendorid broadcast reqopts apn username password pincode auto data lte_apn_use lte_apn lte_username lte_password
	
	case "$service" in
		ecm)
		;;
		eem)
		;;
		mbim)
		;;
		ncm)
			[ -n "$pincode" ] && echo $pincode | gcom -d $ttydev
			USE_APN="$apn" gcom -d $ttydev -s /etc/gcom/ncmconnection.gcom
		;;
		qmi)
			local qmidev=/dev/$(basename $(ls /sys/class/net/${iface}/device/usb/cdc-wdm* -d))
			local CDCDEV="${cdcdev:-$qmidev}"
			[ -n "$pincode" ] && {
				set -o pipefail
				if ! qmicli -d $CDCDEV "--dms-uim-verify-pin=PIN,${pincode}" 2>&1; then
					qmicli -d $CDCDEV --dms-uim-get-pin-status
					proto_notify_error "$config" PIN_FAILED
					proto_block_restart "$interface"
					return 1
				fi
			}
			#qmicli -d $CDCDEV --wds-start-network="$apn" --client-no-release-cid
			qmi-network $CDCDEV start
		;;		
	esac
	
	proto_export "INTERFACE=$config"
	proto_run_command "$config" udhcpc \
		-p /var/run/udhcpc-$iface.pid \
		-s /lib/netifd/dhcp.script \
		-f -t 0 -i "$iface" \
		-x lease:60 \
		${ipaddr:-r $ipaddr} \
		${hostname:-H $hostname} \
		${vendorid:-V $vendorid} \
		$clientid $broadcast $dhcpopts
}

proto_4g_teardown() {
	local interface="$1"
	local iface="$2"
	local service cdcdev ttydev

        config_load network
        config_get service $interface service
        config_get cdcdev $interface cdcdev
        config_get ttydev $interface ttydev        
	
	case "$service" in
		ecm)
		;;
		eem)
		;;
		mbim)
		;;
		ncm)
			USE_DISCONNECT=1 gcom -d $ttydev -s /etc/gcom/ncmconnection.gcom
		;;
		qmi)
			local qmidev=/dev/$(basename $(ls /sys/class/net/${iface}/device/usb/cdc-wdm* -d))
			local CDCDEV="${cdcdev:-$qmidev}"		
			qmi-network $CDCDEV stop
		;;		
	esac
	proto_kill_command "$interface"
}

add_protocol 4g

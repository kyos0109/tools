#!/bin/bash
CUCMD="`whereis cu | cut -d ' ' -f 2`"
if [ ! -f $CUCMD ]; then
	ping 168.95.1.1 -n -c 2 -W 2 &> /dev/null && TNET=0 || TNET=1
	ping 8.8.8.8 -n -c 2 -W 2 &> /dev/null && TNET1=0 || TNET1=1
	if [ $TNET != 0 ] && [ $TNET1 != 0 ]; then
		echo -e "\nError...!!!\n"
        	echo -e "Network is Not Connect.\n"
        	echo -e "Con't Install Test Modem Tools\n"
        	exit 13
	fi	
	yum install uucp -y
fi

MODEMLINE=($(ls /dev | grep tty[SD]))
RCD="/etc/rc.local"
WORKD="/var/spool/hylafax"

while true
do
	echo -e "System Com Port Have ${#MODEMLINE[@]} Port"
	read -p "Please enter the number of the modem [${#MODEMLINE[@]}]: " MODEMValue
	Test_MODEMValue="`echo $MODEMValue | grep [0-9]`"
	if [ "$MODEMValue" == "" ]; then
		MODEMValue="${#MODEMLINE[@]}"
		break
	elif [ "$Test_MODEMValue" == "" ]; then
		echo -e "#################################"
		echo -e "# Error!! You Must Input Number #"
		echo -e "#################################"
	elif [ "$MODEMValue" -lt "${#MODEMLINE[@]}" ]; then
		while true
		do
		read -p "Input The Device Name:[tty?] " Device_Name
		Get_Device_Name=($(echo $Device_Name | grep tty[SD]))
			if [ "$Device_Name" == "" ]; then
				echo "Must Input A Device Name."
			elif [ "$Get_Device_Name" == "" ]; then
				echo "Are You Sure This Device Name??"
				echo "Con't Find The Devices In System."
			elif [ "$Get_Device_Name" != "" ]; then
				break
			fi
		done
		break
	elif [ "$MODEMValue" != "" ]; then
		break
	fi
done

initmodem () {
for ((i=0; i<$MODEMValue; i++));
do
	faxaddmodem -f ${MODEMLINE[$i]} > /dev/null 2>&1 <<EOC
	886
	4
	+1.999.555.1212
	FaxMail
	1
	004
	etc/dialrules
	1
	11
	644
	644
	644
	1
	off
	"-h %l dx_%s"
	""
	""
	etc/lutRS18.pcf
	"From %%l|%c|Page %%P of %%T"
	30
	y
	y
	95
	5
	25
	daemon
	y
	y
	y
	1.0
	default
	y
	y
EOC
	if [ -f $WORKD/FIFI.${MODEMLINE[$i]} ] && [ -f $WORKD/etc/config.${MODEMLINE[$i]} ]; then
		echo "Modem Add ${MODEMLINE[$i]} Done."
		FindFaxgetty_RCD="`cat $RCD | grep -o ${MODEMLINE[$i]}`"
		FindFaxgetty_inPS="`ps aux | grep faxgetty | grep -o ${MODEMLINE[$i]}`"
		if [ "$FindFaxgetty_RCD" == "" ]; then
			echo "/usr/local/sbin/faxgetty -D ${MODEMLINE[$i]}" >> $RCD
			if [ "$FindFaxgetty_inPS" == "" ]; then
				/usr/local/sbin/faxgetty -D ${MODEMLINE[$i]}
				service hylafax restart
			fi
		fi
		rm -rf ${MODEMLINE[$i]}.tmp
	else
		echo "Modem Add ${MODEMLINE[$i]} Fail."
		echo "Tools Command AT to Modem, But Not Echo."
	fi
done
}

if [ "$Get_Device_Name" != ""  ]; then
	MODEMLINE="$Get_Device_Name"
fi

if [ $MODEMValue -gt ${#MODEMLINE[@]} ]; then
	echo -e "\n"
	echo -e "######################################"
        echo -e "# Your System Con't Use More Modem   #"
	echo -e "# Are you kidding?                   #"
	echo -e "######################################"
	echo -e "\n"
	echo -e "Com Port Just Have ${#MODEMLINE[@]} Port"
        exit 13
fi

echo -e "Waiting....\nTest Connection Modem...\n"

for ((i=0; i<${#MODEMLINE[@]}; i++));
do
        cu -l ${MODEMLINE[$i]} > ${MODEMLINE[$i]}.tmp 2>&1 <<EOC
	at
        ~.
EOC
	Modem_Status="`cat ${MODEMLINE[$i]}.tmp  | grep -o OK`"
	if [ "$Modem_Status" != "" ]; then
		echo "${MODEMLINE[$i]}" >> CanUseModem.tmp
		rm -rf ${MODEMLINE[$i]}.tmp
	else
		rm -rf ${MODEMLINE[$i]}.tmp
	fi
done

if [ -f CanUseModem.tmp ]; then
	System_Tested_Modem=($(cat CanUseModem.tmp))
	rm -rf CanUseModem.tmp
else
	System_Tested_Modem="0"
fi

Has_HylaFax_Dev () {
HylaFax_Dev=($(ls $WORKD/etc | grep tty[SD]))
if [ ${#MODEMLINE[@]} != ${#System_Tested_Modem[@]} ]; then
        echo ${HylaFax_Dev[*]} > diff1.tmp
        echo ${System_Tested_Modem[*]} > diff2.tmp
        Diff_File=($(diff diff1.tmp diff2.tmp | cut -d ' ' -f2 | grep -v ^[0-9]))
        for ((a=0; a<${#Diff_File[@]}; a++));
        do
                unset MODEMValue
                MODEMValue="${Diff_File[$a]}"
                initmodem
        done
        rm -rf diff1.tmp
        rm -rf diff2.tmp
fi
}



if [ $MODEMValue != ${#System_Tested_Modem[@]} ]; then
        echo "No Much Value...!!!"
        echo "Modem Have ${System_Tested_Modem[@]} ."
        echo -e "Your Input Value is $MODEMValue\n"
        while true
        do
        read -p "Are You Sure About it [y/n]?" Ans
                if [ "$Ans" == "Y" ] || [ "$Ans" == "y" ]; then
                        echo "Now Auto Setup Modem"
			clear
			echo "Please Wait....."
                        initmodem
                        break
                elif [ "$Ans" == "n" ] || [ "$Ans" == "N" ]; then
                        echo -e "\nExit...."
                        exit 13
                        break
                fi
        done
else
        echo "Now Auto Setup Modem"
        initmodem
fi

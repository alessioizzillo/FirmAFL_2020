#!/bin/bash

# Automatic Start Script that follow the flow and handles the errors

print_usage()
{
    echo "####-USAGE GUIDE-#####"
    echo ""
    echo -e "\033[32m[->]\033[0m Usage: $ sudo ${0} [mode] [firmware]"
    echo ""
    echo "[mode]: use one option at once"
    echo "      -r        Run emulation with qemu-system"
    echo "      -f        FirmAFL web fuzzing"
    echo "      -nf       NEW FirmAFL web fuzzing"
    echo "      -t        Test-mode (run + curl)"    
    echo "      -d        Delete firmware image emulation"
    echo "      -h        Help"
    echo ""
}


if [ $# -eq 0 ] || [ "$1" = "-h" ]; then 
	print_usage
    exit 1
fi

if [ $# -ne 1 ] && [ $# -ne 2 ]; then
    echo -e "\033[31m[-]\033[0m Wrong number of arguments. Please read the USAGE and try again.."
    echo ""
    print_usage ${0}
    exit 1
fi

if (! id | egrep -sqi "root"); then
  echo -e "\033[31m[-]\033[0m This script must run with 'root' privilege"
  exit 1
fi

# Function to find the BRAND, It should be more stable on all possible firmware and not hard coded like this.
# it is not important if here the firmware does not recognize a brand 
auto_find_brand() {

    VAR=${1}
    dlink=("dir" "DIR" "DAP" "dap" "DCH" "dch" "DCS" "dcs" "EBR" "ebr" "DGS" "dgs" "DCS" "dcs" "dhp" "DHP" "dns" "DNS" "DSL" "dsl" "DWR" "dwr" "DWL" "dwl" "DVA" "dva")
    netgear=("R6" "r6" "R8" "r8" "R7" "r7" "WN" "wn" "JWN" "jwn" "EX" "ex" "DM" "dm" "DGN" "dgn" "JNR" "jnr" "DST" "dst" "AC" "ac" "Ac" "AX" "ax" \ 
    "RBR" "rbr" "rbs" "RBS" "XR5" "xr5" "SRS" "SRR" "srs" "srr" "WPN" "wpn" "WAC" "wac" "WGT" "wgt" "EVG" "evg" "D78" "WAG" "wag" "WAC" "wac" "GS" "gs" )
    tplink=("ARCHER" "Archer" "archer" "TL" "tl" "TD" "td" "VR" "vr" "EAP" "eap" "RE" "re" "CPE" "cpe" "WBS" "wbs")
    trendnet=("TEW" "tew" "tv-ip" "fw" "FW")

    for TEST in ${dlink[@]}
    do
        if [[ "${VAR}" == *"$TEST"* ]]; then
            echo "dlink"
            return
        fi
    done
    for TEST in ${netgear[@]}
    do
        if [[ "${VAR}" == *"$TEST"* ]]; then
            echo "netgear"
            return
        fi
    done
    for TEST in ${trendnet[@]}
    do
        if [[ "${VAR}" == *"$TEST"* ]]; then
            echo "trendnet"
            return
        fi
    done
    for TEST in ${tplink[@]}
    do
        if [[ "${VAR}" == *"$TEST"* ]]; then
            echo "tplink"
            return
        fi
    done
    
    echo "NotBrandFound"
}


# Cleanup Process and interfaces
cleanup() {
    sudo umount FirmAE/${WORK_DIR}/dev/null;
    sudo umount FirmAE/${WORK_DIR}/dev/urandom;

    echo -e "\033[33m[*]\033[0m Start Exiting Procedure.."
    echo -e "\033[33m[+]\033[0m Killing Qemu if active"
    
    ID=$(pgrep qemu)
    if [[ ! $ID = "" ]]; then    
        sudo kill -9 ${ID}
        sleep 1
    fi

    echo -e "\033[33m[+]\033[0m Killing all active sub-processes"
    
    # Cleaning any tap interfaces open
    if [ -e scripts/flush_interface.sh ]; then
        ./scripts/flush_interface.sh;
    elif [ -e FirmAE/scripts/flush_interface.sh ]; then
        ./FirmAE/scripts/flush_interface.sh;
    fi

    pkill -15 -f "/bin/bash ./run.sh" || true
    pkill -15 -f "ping -c" || true

    echo -e "\033[32m[+]\033[0m ..End"

    pkill -TERM -P $$ --signal 9;
}

# Cleanup Process and interfaces before exiting
cleanup_exit() {
    cleanup
    exit
}

trap cleanup_exit EXIT

start()
{
    export FUZZ=0;
    export CALLSTACK_TRACING=0;
    export DEBUG=0;
    export FUZZ_APPROACH=0;

    cd FirmAE;

    if ( ! ./scripts/util.py check_connection _ $PSQL_IP ); then
        ./init.sh
        if ( ! ./scripts/util.py check_connection _ $PSQL_IP ); then
            echo -e "[\033[31m-\033[0m] docker container failed to connect to the hosts' postgresql!"
            exit
        fi
    fi

    IID=`./scripts/util.py get_iid $FIRMWARE $PSQL_IP`
    if [[ ${IID} = "" ]] || [[ ! -d scratch/${IID} ]]; then
        if [ ${OPTION} = "-r" ] || [ ${OPTION} = "-f" ] || [ ${OPTION} = "-nf" ]  || [ ${OPTION} = "-t" ]; then
            echo -e "\033[32m[+]\033[0m\033[32m[+]\033[0m FirmAE: Creating Firmware Scratch Image"
            sudo ./run.sh -c ${BRAND} ${FIRMWARE}
            IID=`./scripts/util.py get_iid $FIRMWARE $PSQL_IP`
        fi
    fi    

    WORK_DIR=scratch/${IID}

    echo "IID = $IID"

    if [ -d ${WORK_DIR}/debug ]; then
        sudo rm -r ${WORK_DIR}/debug;
    fi

    cleanup

    # Bind mount to /dev/null and /dev/urandom
    mkdir ${WORK_DIR}/dev 2>&1 > /dev/null;
    touch ${WORK_DIR}/dev/null 2>&1 > /dev/null;
    mount --bind /dev/null ${WORK_DIR}/dev/null;
    touch ${WORK_DIR}/dev/urandom 2>&1 > /dev/null;
    mount --bind /dev/urandom ${WORK_DIR}/dev/urandom;

    if [ ${OPTION} = "-r" ]; then
        #export CALLSTACK_TRACING=1;
        export DEBUG=1;    # Uncomment if you want debug logs.

        if (egrep -sqi "true" ${WORK_DIR}/web); then
            sudo -E ./run.sh -r ${BRAND} $FIRMWARE
        elif (! egrep -sqi "false" ping); then
            # Case where PING is TRUE, WEB is FALSE. Type of fuzzing?
            echo "WEB is FALSE and PING IS TRUE" 
            return
        else   
            # Case where both WEB and PING are False. Type of fuzzing?
            echo "WEB and PING ARE FALSE"
            return
        fi
    
    elif [ ${OPTION} = "-t" ]; then
        #export CALLSTACK_TRACING=1;
        export DEBUG=1;    # Uncomment if you want debug logs.

        # Retrieve ip addresses of the firmware, to do later the print
        IPS=()
        if (egrep -sq true isDhcp); then
            IPS+=("127.0.0.1")
        else
            IP_NUM=`cat ip_num`
            for (( IDX=0; IDX<${IP_NUM}; IDX++ ))
            do
                IPS+=(`cat ip.${IDX}`)
            done
        fi

        if (egrep -sqi "true" ${WORK_DIR}/web); then
            sudo -E ./run.sh -r ${BRAND} $FIRMWARE 2>&1 > ${WORK_DIR}/run_emulation.log &
        elif (! egrep -sqi "false" ping); then
            # Case where PING is TRUE, WEB is FALSE. Type of fuzzing?
            echo "WEB is FALSE and PING IS TRUE" 
            return
        else   
            # Case where both WEB and PING are False. Type of fuzzing?
            echo "WEB and PING ARE FALSE"
            return
        fi
        echo -e "\033[33m[*]\033[0m Let's wait 60 seconds...\n"
        sleep 60
        cd ..
        echo -e "\033[33m[*]\033[0m Trying to connect to the web server..."
        for (( IDX=0; IDX<${IP_NUM}; IDX++ ))
        do
            echo "http://${IPS[${IDX}]}";
            python3 curl.py ${IPS[${IDX}]};
        done
        echo ""
        cd -
        echo -e "\033[33m[*]\033[0m Let's wait 30 seconds...\n"
        sleep 30

    elif [ ${OPTION} = "-f" ] || [ ${OPTION} = "-nf" ]; then
        export FUZZ=1;
        #export CALLSTACK_TRACING=1;
        export DEBUG=1;    # Uncomment if you want debug logs.
        if [ ${OPTION} = "-nf" ]; then
            echo -e "\033[33m[*]\033[0m Chosen Fuzzing Approach: NEW"
            export FUZZ_APPROACH=1;
        else
            echo -e "\033[33m[*]\033[0m Chosen Fuzzing Approach: ORIGINAL"
        fi

        # First check on the firmware correctness for fuzzing
        # NORMAL Case where PING is TRUE, WEB is TRUE.
        if (egrep -sqi "true" ${WORK_DIR}/web); then
            # We have to wait that the firmware is up. Then we can start
            echo -e "\033[33m[*]\033[0m Starting emulation of the firmware..."
            echo -e "\033[33m[*]\033[0m Emulation Log -> ${WORK_DIR}/run_emulation.log \n"
            
            # First I start qemu-system mode of the firmware and put it in background
            sudo -E ./run_firmafl.sh -f ${BRAND} $FIRMWARE 2>&1 > ${WORK_DIR}/run_emulation.log &
            pid=$!
            echo -e "\033[33m[*]\033[0m Let's wait 60 seconds...\n"
            sleep 60
            count=$(ps -A| grep $pid |wc -l) # Check whether process is still running

            if [[ $count -eq 0 ]]; then 
                # If process is already terminated error
                echo -e "\033[31m[-]\033[0m Something went wrong, emulation of qemu-system-${ARCH} failed!"
                exit     
            fi
            
            # Enter to the WorkFolder to start the fuzzer
            cd ${WORK_DIR}

            # Retrieve ip addresses of the firmware, to do later the print
            IPS=()
            if (egrep -sq true isDhcp); then
                IPS+=("127.0.0.1")
            else
                IP_NUM=`cat ip_num`
                for (( IDX=0; IDX<${IP_NUM}; IDX++ ))
                do
                    IPS+=(`cat ip.${IDX}`)
                done
            fi

            echo -e "\033[33m[*]\033[0m Trying to connect to the web server..."
            for (( IDX=0; IDX<${IP_NUM}; IDX++ ))
            do
                echo "http://${IPS[${IDX}]}";
                curl --max-time 2 --output /dev/null --silent http://${IPS[${IDX}]};
            done
            echo ""

            echo -e "\033[33m[*]\033[0m Let's wait 5 seconds...\n"
            sleep 5

            echo -e "\033[32m[+]\033[0m Web server has been reached !"
            
            # Some Web Services may have been already activated without POST request, so we handle this case.
            MAP_TAB_LINES=$(wc -l < mapping_table | xargs)
            if [ ${MAP_TAB_LINES} -gt 20 ]; then
                echo -e "\033[32m[+]\033[0m The Mapping Table of the binary program has been configured successfully!"

            else
                echo -e "\033[31m[-]\033[0m Mapping Table is not configured! Without configuration you will have problems later...we are stopping here. See the README to know more"
                exit
            fi

            echo ""
            echo -e "\033[32m[+]\033[0m All set..Now we can start the fuzzer"
            if [[ -f "fuzz_line" ]]; then
                AFL=$(cat fuzz_line)
            else
                AFL="./afl-fuzz -m none -t 800000+ -Q -i inputs -o outputs -x keywords"
            fi

            if [[ -f "service" ]]; then
                TARGET_PROGRAM_PATH=$(cat service)
            else
                echo -e "\033[31m[-]\033[0m The target program has not been specified!"
                exit 
            fi
            echo -e "\033[32m[->]\033[0m $AFL $TARGET_PROGRAM_PATH"
            echo -e "\033[32m[->]\033[0m To change it go to FirmAE/scratch/<ID>/fuzz_line"
            sleep 3
  
            # The fuzzer cannot start with an already existing /outputs folder so we removes it
            if [ -e outputs ]; then
                sudo rm -r outputs;
            fi

            # Some configuration lines of the fuzzer
            echo core | sudo tee /proc/sys/kernel/core_pattern;
            export AFL_SKIP_CPUFREQ=1;

            TARGET_PROGRAM_PATH=${TARGET_PROGRAM_PATH%%[[:space:]]*}
            TARGET_PROGRAM_PATH="${TARGET_PROGRAM_PATH:1}"
            
            chroot . ${AFL} ${TARGET_PROGRAM_PATH} @@

            # Exiting the WorkFolder
            cd -
           
        elif (! egrep -sqi "false" ping); then
            # Case where PING is TRUE, WEB is FALSE. Type of fuzzing?
            echo "WEB is FALSE and PING IS TRUE - What type of fuzzing we do? At the moment exiting" 
            return

        else   
            # Case where both WEB and PING are False. Type of fuzzing?
            echo "WEB and PING ARE FALSE - What type of fuzzing we do? At the moment exiting"
            return
        fi

        echo -e "\033[32m[+]\033[0m\033[32m[+]\033[0m Ending Fuzzing Session - Check the result on the outputs directory!"

    fi

    cd ..
}

PSQL_IP=127.0.0.1
OPTION=${1}
FIRMWARE=${2}
BRAND=$(auto_find_brand ${FILENAME})
IID=0

# I will be working in FirmAE directory, so I adjust the firmware relative path if needed
firstCharacter=${FIRMWARE:0:1}
if [ ! $firstCharacter = "/" ]; then
    FIRMWARE="../${FIRMWARE}"
fi

start ${FIRMWARE}

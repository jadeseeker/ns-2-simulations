#!/bin/bash -e

declare -a FLAVORS=("tahoe" "reno" "newreno" "sack1")
declare -a OUTPUTS=("Flow*" "congestion*" "tcp.tr" "tcp.nam" "CW.png" "Throughput.png" "*.stdout")

RSEED=0
ERROR=0
for FLAVOR in "${FLAVORS[@]}"
do
    echo "[Run ${FLAVOR}]"
    DIR="${FLAVOR}"

    rm -r ${DIR}
    mkdir ${DIR}

    echo "  - run NS2..."
    ns tcp.tcl ${ERROR} ${RSEED} ${FLAVOR} > ${FLAVOR}_ns2.stdout 

    echo " - process trace..."
    python process_trace.py > ${FLAVOR}_python.stdout
   
    echo " - coppy results..."    
    for OUTPUT in "${OUTPUTS[@]}"
    do
        mv ${OUTPUT} ${DIR}
    done
    
done

#!/bin/bash -e

THROUGHPUT="all_throughput.txt"

declare -a FLAVORS=("tahoe" "reno" "newreno" "sack1")

for FLAVOR in "${FLAVORS[@]}"
do
    rm ${THROUGHPUT}
    for ERROR in `seq 0 10`
    do
        echo "[ERROR ${ERROR}]" >>  ${THROUGHPUT}
    
        for RSEED in `seq 1 20`
        do
            ns tcp.tcl ${ERROR} ${RSEED} ${FLAVOR}
            python process_trace.py
        done

        echo "  " >>  ${THROUGHPUT}
    done

    cp ${THROUGHPUT} ${FLAVOR}_${THROUGHPUT}
done

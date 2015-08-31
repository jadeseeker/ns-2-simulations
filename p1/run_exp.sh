#!/bin/bash -e

for ERROR in `seq 0 10`
do
    for RSEED in `seq 1 20`
    do
        ns project1.tcl ${ERROR} ${RSEED}
    done
done

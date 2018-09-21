#!/bin/bash

## TDoA reprocessing using kiwiproxy data
##   log files: $FILES_PATH/"num".log
##   example:  FILES_PATH="path to files" ./proc_tdoa_kiwi.sh num1 num2 ...

FILES_PATH=${FILES_PATH-../files} ## default is ../files

function do_proc {
    local r=$1
    local fs=$(find ${FILES_PATH}/$r -name "*.wav" -print)
    local ff=""
    for f in $fs; do
	ff="'$f',$ff"
    done
    ff="{${ff:0:-1}}"
    local dir="'${FILES_PATH}/$r'"

    rm -f ${FILES_PATH}/$f/status.json

    local west=$(cat ${FILES_PATH}/$r/*json | awk '/west/{print 1*$2}' | sort -rn | tail -1)
    local south=$(cat ${FILES_PATH}/$r/*json | awk '/south/{print 1*$2}' | sort -rn | tail -1)
    local east=$(cat ${FILES_PATH}/$r/*json | awk '/east/{print 1*$2}' | sort -n | tail -1)
    local north=$(cat ${FILES_PATH}/$r/*json | awk '/north/{print 1*$2}' | sort -n | tail -1)
    if [ X$west  == X ] || [ X$south == X ] || [ X$north == X ] || [ X$east  == X ]; then
        echo "no maps found"
        return
    fi

    local plot_info="struct('lat_range', [$south $north],'lon_range', [$west $east])"
    echo $dir, $ff, $plot_info

    cat <<EOF | QT_X11_NO_MITSHM=1 LD_PRELOAD=libGLX_mesa.so.0 octave-cli ## octave --no-gui ##
proc_tdoa_kiwi($dir, $ff, $plot_info);
exit
EOF

    cat ${FILES_PATH}/$r/status.json
    jsonlint-php ${FILES_PATH}/$r/status.json
}

n=$(echo $@ | wc -w)
counter=0
for r in $@; do
    counter=$((1 + $counter))
    echo $r $counter/$n
    do_proc $r 2>&1 > ${FILES_PATH}/$r.log &
    if [ $(( $counter %4 )) == 0 ]; then
        wait
        counter=0
    fi
    wait
done

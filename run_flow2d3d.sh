#!/bin/bash
env
mkdir -p /onedata/input
mkdir -p /onedata/output

ONECLIENT_AUTHORIZATION_TOKEN="$INPUT_ONEDATA_TOKEN" PROVIDER_HOSTNAME="$INPUT_ONEDATA_PROVIDERS" oneclient --no_check_certificate --authentication token -o ro /onedata/input || exit 1
ONECLIENT_AUTHORIZATION_TOKEN="$OUTPUT_ONEDATA_TOKEN" PROVIDER_HOSTNAME="$OUTPUT_ONEDATA_PROVIDERS" oneclient --no_check_certificate --authentication token -o rw /onedata/output || exit 1

echo Start at $(date)

INPUTDIR="/onedata/input/$INPUT_ONEDATA_SPACE/$INPUT_PATH"
OUTPUTDIR="/onedata/output/$OUTPUT_ONEDATA_SPACE/$OUTPUT_PATH"

mkdir -p "$OUTPUTDIR" # create if it does not exists
TEMPW=$(mktemp -d --tmpdir="/data" workspace.XXXXXXXXXX)

WORKDIR="$TEMPW"

# Extract input
echo Extracting input

#find "$INPUTDIR" -name "*.tar.gz" -exec tar xfz {} --no-same-owner -C "$WORKDIR" \; || exit 1
cp $INPUTDIR/* $WORKDIR || exit 1
cd "$WORKDIR" || exit 2

echo Listing directory content:
ls -latr
echo "*************"

chmod 777 ./*.sh


init_time=$(date +%s)
argfile=config_flow2d3d.xml
free -h

    #
    # Set the directory containing delftflow.exe here
    #
exedir=$D3D_BIN/bin/lnx64/flow2d3d/bin
export LD_LIBRARY_PATH=$exedir:$LD_LIBRARY_PATH
free -h

    # Run
$exedir/d_hydro.exe $argfile

free -h
finish_time=$(date +%s)
echo $(expr $finish_time - $init_time)

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
TEMPW=$(mktemp -d --tmpdir="$OUTPUTDIR" workspace.XXXXXXXXXX)

WORKDIR="$TEMPW"



# Extract input
echo Extracting input

find "$INPUTDIR" -name "*.tar.gz" -exec tar xfz {} --no-same-owner -C "$WORKDIR" \; || exit 1
cd "$WORKDIR" || exit 2

echo Listing directory content:
ls -latr
echo "*************"

chmod 777 ./*.sh

echo Editing $D3D_PARAM with value $D3D_VALUE

if [ ! -z $D3D_PARAM ]; then
 sed -i "s/.* ; $D3D_PARAM/$D3D_VALUE ; $D3D_PARAM/g" $INPUT_CONFIG_FILE || exit 1
 grep "; $D3D_PARAM" $INPUT_CONFIG_FILE
fi

echo Run test
# Run Rscript
# ./run_delwaq.sh > log.txt  || exit 1
inpfile=$INPUT_CONFIG_FILE

currentdir=`pwd`
echo $currentdir
argfile=$currentdir/$inpfile

    #
    # Set the directory containing delwaq1 and delwaq2 and
    # the directory containing the proc_def and bloom files here
    #
exedir=$D3D_BIN/bin/lnx64/waq/bin
export LD_LIBRARY_PATH=$exedir:$LD_LIBRARY_PATH
procfile=$D3D_BIN/bin/lnx64/waq/default/proc_def

    #
    # Run delwaq 1
    #
$exedir/delwaq1 $argfile -eco $D3D_BIN/bin/lnx64/waq/default/bloom.spe -p "$procfile"

    #
    # Wait for any key to run delwaq 2
    #
if [ $? == 0 ]
  then
    echo ""
    echo "Delwaq1 did run without errors."

    #
    # Run delwaq 2
    #
    echo ""
    $exedir/delwaq2 $argfile

    if [ $? -eq 0 ]
      then
        echo ""
        echo "Delwaq2 did run without errors."
      else
        echo ""
        echo "Delwaq2 did not run correctly."
    fi
else
    echo ""
    echo "Delwaq1 did not run correctly, ending calculation"
fi
sleep 3

# Collect output
echo Compressing output: 
#tar cfz "$OUTPUTDIR"/"$OUTPUT_FILENAMES" * 

cp ./*.hda "$OUTPUTDIR"
cp ./*.hdf "$OUTPUTDIR"
cp ./*.txt "$OUTPUTDIR"
cp ./*.inp "$OUTPUTDIR"
cp ./*.lga "$OUTPUTDIR"
cp ./*.lsp "$OUTPUTDIR"
cp ./*.lst "$OUTPUTDIR"

echo Output file: "$OUTPUTDIR"/"$OUTPUT_FILENAMES"

cd -

echo Cleaning temp workspace
rm -rf "$WORKDIR"/* && rm -rf "$WORKDIR"


echo End at $(date)

sleep 5

umount /onedata/input || exit 1
umount /onedata/output || exit 1

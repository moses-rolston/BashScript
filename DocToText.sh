#!/bin/bash

size=0
destLocation=/Volumes/Projects/MobileApps/Test/project/parameters.txt

function printEmptyLines() {
    echo " "
    echo " "
    echo " "
}

function callForFailure() {
    echo "Failed to execute the command at $1"
    echo " !!!!!!!!!!!!!!! Failure !!!!!!!!!!!!!!!!!!!!!" && printEmptyLines && cd error
    exit
}

function startWork() {
    cd "$1"
    docFilesCount=$(find . -type f \( -name "*.doc" -or -name "*.docx" \)|wc -l) || callForFailure "Checking the count of doc file"
    docFileName=$(find . -type f \( -name "*.doc" -or -name "*.docx" \)) || callForFailure "getting the names of doc files"
    fileName=$(basename $docFileName) || callForFailure "getting the base name of doc file"
    if [ $docFilesCount -eq 0 ] ; then
        echo "******The document file is missing.*******"
        callForFailure "no doc files available"
    else
        echo "Number of document files found " $docFilesCount
        echo "Name of the document file is --> $fileName"
        pwd
        for i in *.docx ; do
            echo $i
            unzip -p "$i" | grep '<w:t' | sed 's/<[^<]*>/\
            /g' | grep -v '^[[:space:]]*$' > WordToText.txt || callForFailure "Conversion of doc to text call"
        done
    fi
}

function processIPAFile() {
    echo "NOT A ZIP FILE."
    callForFailure "NOT A ZIP FILE."
}

printEmptyLines

while read parameters; do
    if [ $size = 0 ]; then
        isZip="$parameters"
        size=1
    else
        count="$parameters"
    fi
done < $destLocation || callForFailure "reading the parameters"

if [ "$isZip" = true ]; then
    if [ $count -gt 0 ]; then
        echo "./">$destLocation || callForFailure "writing the current directory to parameters"
        startWork "./" || callForFailure "starting the process/work for count of files greater than 0"
    else
#IFS="/" read -a array <<< "$1"
#IFS="." read -a folderArray <<< "${array[5]}"
        for i in * ; do
            if [ "$i" = "parameters.txt" ]; then
                echo "continue....."
            elif [ -d "$i" ]; then
                echo "FileName $i"
                echo "$i">$destLocation || callForFailure "writing the file name to parameters"
                startWork "$i" || callForFailure "starting the process/work for a directory existance"
            else
                echo "FileName $i"
                echo "Folder named $i does not exist."
                for D in `ls ./`
                do
                    echo "./$D">$destLocation || callForFailure "writing the destination to parameters"
                    echo "Folder $D exists."
                    startWork "./$D" || callForFailure "starting the process/work for some files"
                done
            fi
        done
    fi
else
    echo "Skipping the DocToText step..."
    echo "Skip Parse">$destLocation || callForFailure "writing Skip Parse to parameters"

fi

printEmptyLines

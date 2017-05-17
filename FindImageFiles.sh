#!/bin/bash

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

isReturn=false
while read parameters; do
    if [ "$parameters" = "Skip Parse" ]; then
        printEmptyLines
        echo "Skip Find Images"
        isReturn=true
        break
    else
        file="$parameters"
    fi
done < $destLocation || callForFailure "reading the parameters"

function findImages() {
    echo ">>>>>>>>>>>>>>>>>>>>>  Finding the image files...  <<<<<<<<<<<<<<<<<<<<<<<<<<<"
    imageFiles=$(find . -type f \( -name "*.png" -or -name "*.jpg" -or -name "*.PNG" \)|wc -l) || callForFailure "finding the count of png and jp files"
    if [ $imageFiles -eq 0 ] ; then
        echo "******The image file is missing.*******"
        callForFailure "find images returned zero image files"
    else
        echo "Number of image files found " $imageFiles
        imageFileName=$(find . -type f \( -name "*.png" -or -name "*.jpg" -or -name "*.PNG"  \)) || callForFailure "finding the image file names"
        echo "Name of the image file is -->     $imageFileName"
    fi
}

if [ "$isReturn" = true ]; then
    printEmptyLines
else
    cd "$file"
    printEmptyLines
    findImages
    printEmptyLines
fi

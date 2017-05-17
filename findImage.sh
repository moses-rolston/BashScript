#!/bin/sh
echo "**********************************************************************"
echo "Finding the image files..."
imageFiles=$(find ../project/${folderArray[0]} -type f \( -name "*.png" -or -name "*.jpg" \)|wc -l)
if [ $imageFiles -eq 0 ] ; then
        echo "******The image file is missing.*******"
else
        echo "Number of image files found " $imageFiles
        echo "Name of the image file is -->"
        find ../project/ -type f \( -name "*.png" -or -name "*.jpg" \)
fi
exit

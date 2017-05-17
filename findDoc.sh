#!/bin/sh
echo "**********************************************************************"
echo "Finding the Word document..."
cd "$1"
docFilesCount=$(find . -type f \( -name "*.doc" -or -name "*.docx" \)|wc -l)
docFileName=$(find . -type f \( -name "*.doc" -or -name "*.docx" \))
fileName=$(basename $docFileName)
echo "FileName $fileName"
isX=false
echo "newFile $NEW_APP"
if [ $docFilesCount -eq 0 ] ; then
        echo "******The document file is missing.*******"
else
        echo "Number of document files found " $docFilesCount
        echo "Name of the document file is --> $fileName"
        for i in *.docx ; do
            echo "Parsing of $i is in process. Please wait..."
            unzip -p "$i" | grep '<w:t' | sed 's/<[^<]*>/\
            /g' | grep -v '^[[:space:]]*$' > New.txt
            while read p; do
                if [ "$p" == "X" ] ; then
                    isX=true
                elif [ "$isX" == true ] ; then
                    if [ "$p" == "New App" ]; then
                        NEW_APP=true
                        echo "New app assignment"
                        isX=false
                    elif [ "$p" == "Update Existing App" ]; then
                        UPDATE_EXISTING_APP=true
                        echo "Update Existing App Assignment"
                        isX=false
                    elif [  "$p" == "Remove App from Appstore" ]; then
                        REMOVE_APP_FROM_STORE=true
                        echo "Remove App from Appstore Assignment"
                        isX=false
                    fi
                fi
            done < New.txt
        isX=false
        done
fi
if [ "$NEW_APP" == false ]; then
    if [ "$UPDATE_EXISTING_APP" == false ];  then
        if [ "$REMOVE_APP_FROM_STORE" = false ]; then
            echo "No proper selection made for this request (New App, Update, Remove)"
            echo":"
        fi
    fi
fi
echo "file: $NEW_APP"
exit


#!/bin/bash

JENKINS_WORK_SPACE="/Users/a.appsubmission/.jenkins/jobs/UnZipProcess/workspace"

SHARED_DISK_VOLUME="/Volumes/Projects/MobileApps/Production"

CURRENT_WORKSPACE="$SHARED_DISK_VOLUME"
CURRENT_PROJECT="$CURRENT_WORKSPACE/project"
CURRENT_UPLOAD="$CURRENT_WORKSPACE/UploadZipFiles"
CURRENT_PARAMETER_LOCATION="$CURRENT_PROJECT/parameters.txt"
CURRENT_ALT_PARAMETER_LOCATION="$CURRENT_WORKSPACE/parameters.txt"
CURRENT_PROJECTS="$CURRENT_WORKSPACE/Projects"

function printEmptyLines() {
    echo " "
    echo " "
    echo " "
}

function callForFailure() {
    Result="Failed to execute the command at $1"
    echo "$Result"
    Result=$(echo "$Result" | sed -e "s/ /%20/g")
    CLIENT_URL="$CLIENT_URL?BoDept=$arrayNames[0]&AppTitle=$APPNAME&Result=$Result"
    echo "$CLIENT_URL"
    curl -s "$CLIENT_URL"
    echo " !!!!!!!!!!!!!!! Failure !!!!!!!!!!!!!!!!!!!!!" && printEmptyLines && cd error
    exit
}

echo "**********************************************************************"
cd "$CURRENT_WORKSPACE"  || callForFailure "Unable to access the Shared Drive." 
#|| mkdir -p /Volumes/Projects && mount_smbfs //NKE-WIN-NAS-P22/Projects /Volumes/Projects 
pwd
echo "CLIENT_URL: $CLIENT_URL"

function unzipCall() {
    echo "Clearing the project folder..."
    chmod -R 777 ./project && 
    rm -rf -- ./project || callForFailure "permissions change and removal of project folder"
    echo "****************************"
    echo "Unzipping the package..."
    unzip "$1" -d ./project >> results.txt || callForFailure "Unzipping the zip file"
}

printEmptyLines
echo "FolderName $FOLDERNAME"
doFolderExist=false;
doZipExist=false
 
echo ""
#Reading the Zip file and moving to Target.zip file.
file="$CURRENT_UPLOAD/$FOLDERNAME"
    IFS="/" read -a fileDetails <<< "$file" || callForFailure "Splitting the File name against /"
    length="${#fileDetails[@]}"
    names=$(echo ${fileDetails[$length-1]} | sed -e "s/.zip//g") || callForFailure "Finding the file name without extension"
    echo "name $names"
    if [ "$FOLDERNAME" == "$names.zip" ]; then
        IFS="___" read -a arrayNames <<< "$names" || callForFailure "Splitting the File name against ___"
        echo "names ${arrayNames[0]} ${arrayNames[1]}"
        names="$APPNAME"
        mv $file "$CURRENT_WORKSPACE/Target.zip"
        doZipExist=true
     elif [ -d "$file" ]; then
     	IFS="/" read -a fileDetails <<< "$file" || callForFailure "Splitting the File name against /"
    	length="${#fileDetails[@]}"
    	names=$(echo ${fileDetails[$length-1]} | sed -e "s/.zip//g") || callForFailure "Finding the file name without extension"
    	echo "name $names"
    	IFS="___" read -a arrayNames <<< "$names" || callForFailure "Splitting the File name against ___"
    	echo "names ${arrayNames[0]} ${arrayNames[1]}"
    	names="$APPNAME"
    	doFolderExist=true
    fi

echo "Processing the file which is doFolderExist: $doFolderExist, doZipExist=$doZipExist"

<<COMMENT12
for file in "$CURRENT_UPLOAD/*.zip" ; do
    IFS="/" read -a fileDetails <<< "$file" || callForFailure "Splitting the File name against /"
    length="${#fileDetails[@]}"
    names=$(echo ${fileDetails[$length-1]} | sed -e "s/.zip//g") || callForFailure "Finding the file name without extension"
    echo "name $names"
    if [ "$FOLDERNAME" == "$names.zip" ]; then
        IFS="___" read -a arrayNames <<< "$names" || callForFailure "Splitting the File name against ___"
        echo "names ${arrayNames[0]} ${arrayNames[1]}"
        names="$APPNAME"
        mv $file "$CURRENT_WORKSPACE/Target.zip"
        doFolderExist=true
        break
    fi
done
COMMENT12

if [ $doZipExist == "false" ] && [ $doFolderExist == "true" ]; then
	isZip=false
	pwd
	if [ -d "./project" ]; then
		echo "Clearing the project folder..."
    	chmod -R 777 ./project && 
    	rm -rf -- ./project || callForFailure "permissions change and removal of project folder"
    fi
    echo "****************************"
    mv "$file" "$CURRENT_UPLOAD/project" || callForFailure "Unable to move $file to ./project folder."
    mv "$CURRENT_UPLOAD/project" "$CURRENT_WORKSPACE" || callForFailure "Unable to move project folder to workspace folder."
elif [ $doZipExist == "true" ] && [ $doFolderExist == "false" ]; then
	isZip=true
	unzipCall ./Target.zip || callForFailure "Unzip method call."
	if [ -d ./project/__MACOSX ]; then
    	chmod 777 ./project/__MACOSX || callForFailure "Changing the permissions of __MACOSX."
    	rm -rf ./project/__MACOSX || callForFailure "removal of __MACOSX"
	fi
else
	callForFailure "Project folder/zip does not exist"
fi

APPNAME=$(echo $APPNAME | sed -e "s/.zip//g") || callForFailure "Finding the file name without extension"




countFolder=0
countIPA=0
countDoc=0
countImage=0

isFolder=false
isIPA=false
isDoc=false
isImage=false

folderName=""
IPAName=""
docName=""

projectType=0

cd project || callForFailure " at change directory to project"
echo "Processing the file structure..."
for i in * ; do 
    echo "type of file $i"
    if [ -d "$i" ]; then
        isFolder=true
        countFolder=$countFolder+1
        folderName="$i"
    else
        type=$(echo "$i" |awk -F . '{if (NF>1) {print $NF}}')
        if [ "$type" == "ipa" ]; then
            countIPA=$countIPA+1
            isIPA=true
            IPAName="$i"
        elif [ "$type" == "doc" -o "$type" == "docx" ]; then
            countDoc=$countDoc=+1
            isDoc=true
            docName="$i"
        elif [ "$type" == "png" -o "$type" == "PNG" -o "$type" == "jpg" -o "$type" == "jpeg" -o "$type" == "JPG" -o "$type" == "JPEG" -o "$type" == "bmp" ]; then
            countImage=$countImage+1
            isImage=true
        fi
    fi
done || callForFailure " at Processing the file structure..."

if  [ $isFolder = false -a $isIPA = true -a $isDoc = false -a $isImage = false ]; then    #Just IPA file inside the zip file
    projectType=1
elif [ $isFolder = true -a $isIPA = false -a $isDoc = false -a $isImage = false ]; then   # Just folder inside the zip file
    projectType=2
    cd "$folderName"
    for i in *.ipa ; do 
        echo "type of file $i"
        IPAName="$i" 
        echo "IPA Name $IPAName"
    done
elif [ $isFolder = false -a $isIPA = true -a $isDoc = true -a $isImage = true ]; then   # IPA, Doc and Image inside the zip file
    projectType=3
    callForFailure "Improper file structure. Only .ipa file or Folder/.ipa is allowed. No Images or doc files"
elif [ $isFolder = false -a $isIPA = true -a $isDoc = true -a $isImage = false ]; then   # IPA, Doc inside the zip file
    projectType=3
    callForFailure "Improper file structure. Only .ipa file or Folder/.ipa is allowed. No Images or doc files"
elif [ $isFolder = true -a $isIPA = false -a $isDoc = true -a $isImage = true ]; then   # Folder, Doc and Image inside the zip file
    projectType=4
    callForFailure "Improper file structure. Only .ipa file or Folder/.ipa is allowed. No Images or doc files"
elif [ $isFolder = true -a $isIPA = false -a $isDoc = true -a $isImage = false ]; then   # Folder, Doc and Image inside the zip file
    projectType=4
    callForFailure "Improper file structure. Only .ipa file or Folder/.ipa is allowed. No Images or doc files"
else
    projectType=5
    callForFailure "Improper file structure. No IPA file."
fi

urlParameters="?BoDept=${arrayNames[0]}&AppTitle=$APPNAME"

echo "*BUNDLE_ID*">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"
echo "$BUNDLE_ID">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"

echo "*CLIENT_URL*">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"
echo "$CLIENT_URL">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"

echo "*ProjectType*">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"
echo "$projectType">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"

echo "*IPA*">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"
echo "$isIPA">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"
echo "$IPAName">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"
echo "IPA Name $IPAName"

echo "*Folder*">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"
echo "$isFolder">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"

echo "$urlParameters">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"

echo "data">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"

echo "*isPush*">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing removal to parameters"

echo "$IS_PUSH">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing removal to parameters"

echo "$APP_REQUEST_TYPE">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"

echo "$VERSION">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing version number to parameters file"

echo "$APPNAME">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing the application title to parameters file"

echo "$folderName">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"

CLIENT_URL="$CLIENT_URL$urlParameters&Result=Unzipping%20is%20successful."
echo "$CLIENT_URL"
curl -s "$CLIENT_URL"
printEmptyLines

exit
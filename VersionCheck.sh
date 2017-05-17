#!/bin/bash

JENKINS_WORK_SPACE="/Users/a.appsubmission/.jenkins/jobs/UnZipProcess/workspace"

SHARED_DISK_VOLUME="/Volumes/Projects/MobileApps/Production"

CURRENT_WORKSPACE="$SHARED_DISK_VOLUME"
CURRENT_PROJECT="$CURRENT_WORKSPACE/project"
CURRENT_PARAMETER_LOCATION="$CURRENT_PROJECT/parameters.txt"
CURRENT_ALT_PARAMETER_LOCATION="$CURRENT_WORKSPACE/parameters.txt"
CURRENT_PROJECTS="$CURRENT_WORKSPACE/Projects"


function printEmptyLines() {
    echo " "
    echo " "
    echo " "
}

function callForFailure() {
    Result="Failed: $1"
    echo "$Result"
    Result=$(echo "$Result" | sed -e "s/ /%20/g")
    CLIENT_URL="$CLIENT_URL$urlParameters&Result=$Result"
    curl -s "$CLIENT_URL"
    echo " !!!!!!!!!!!!!!! Failure !!!!!!!!!!!!!!!!!!!!!" && printEmptyLines && cd error
    exit
}

function isInteger() {
    Number="$1"
    if [ "${Number:0:1}" = "-" ]    #extract first character
    then
        RemNumber="${Number:1}"     #extract except first char
    else
        RemNumber="$Number"
    fi
    if [ -z "$RemNumber" ]
    then
        echo "Not an Integer"
    else
        NoDigits="$(echo $RemNumber | sed 's/[[:digit:]]//g')"
        if [ -z "$NoDigits" ]
        then
            echo "An Integer"
        else
            echo "Not an Integer."
        fi
    fi
}

function versionCheck() {
    pListVersionNumber=$(/usr/libexec/PlistBuddy -c "print :CFBundleVersion" "$1") || callForFailure "Could not find Version Number in Plist file."

    echo "$pListVersionNumber">>"$CURRENT_PARAMETER_LOCATION"
    echo "$pListVersionNumber">>"$CURRENT_ALT_PARAMETER_LOCATION"

    IFS="." read -a arrayVersionNumber <<< "$pListVersionNumber" || callForFailure "Version Number format $pListVersionNumber is improper format. Please follow this format *.*.* i.e. for example 1.0.1"
    versionCount="${#arrayVersionNumber[@]}" || callForFailure "Version Number format $pListVersionNumber is in improper format. Please follow this format *.*.* i.e. for example 1.0.1"
    if [ "$version" = "" ]; then
        version="1"
        for (( i=1; i<$versionCount; i++ ))
        do
            version=$version".0"
        done
    fi
    IFS="." read -a arrayDocVersionNumber <<< "$version" || callForFailure "Internal error in reading old version number $version. Please check with admin: mobileapp@nike.com."
    docVersonCount="${#arrayDocVersionNumber[@]}" || callForFailure "Internal error in reading old version number $version. Please check with admin: mobileapp@nike.com."
    if [ "$versionCount" -gt "$docVersonCount" ]; then
        for (( i=$docVersonCount; i<$versionCount; i++ ))
        do
            version=$version".0"
        done
        docVersonCount="$versionCount"
    else
        difference=$(( ${docVersonCount} - ${versionCount} ))
        for (( j=0; j<$difference; j++ ))
        do
            arrayVersionNumber[$versionCount+$j]='0' || callForFailure "$1 Unable to process pList version number $pListVersionNumber and old version number $version"
        done
        versionCount=$(( $versionCount + ${difference} )) || callForFailure "$1 Unable to process pList version number $pListVersionNumber and old version number $version"
    fi
    echo "the size of array arrayVersionNumber $versionCount"
    IFS="." read -a arrayDocVersionNumber <<< "$version" || callForFailure "$1 Unable to process pList version number $pListVersionNumber and old version number $version"
    if [ "$versionCount" -eq "$docVersonCount" ]; then
        isIncremented=false
        isEqual=false
        for (( i=1; i<=$versionCount; i++ ))
        do
            vDN=${arrayDocVersionNumber[$i-1]} || callForFailure "accessing the arrayDocVersionNumber with position $i-1"
            vN=${arrayVersionNumber[$i-1]} || callForFailure "accessing the arrayVersionNumber with Position $i-1"
            valueChecked=$(isInteger "$vN") || callForFailure "isInteger method call with parameters $vN"
            #Check whether the call is for Version increment as part of Profile Renewal maintenance or just for signing the app
            if [ "$valueChecked" = "Not an Integer" ]; then
                callForFailure "Version number have text. Improper version number format."
            else
                if [ $vN -ge $vDN ]; then
                    if [ $vN -gt $vDN ]; then
                        isIncremented=true
                        isEqual=false
                        break
                    else
                        isEqual=true
                        isIncremented=false
                    fi
                else
                    callForFailure "Version number is not incremented. Old Version number is $version and requested app version number is $pListVersionNumber"
                fi
            fi
        done
        if [ "$isIncremented" = true ]; then
            echo "Version number is incremented. Requested app Version number ($pListVersionNumber) > Old app version number ($version)"
#        elif [ "$isEqual" = true ]; then
#            echo "Version number is not incremented. But Requested app Version number ($pListVersionNumber) = Old app version number ($version)"
        else
            echo "Version number is not incremented. Requested app Version number ($pListVersionNumber) < Old app version number ($version)"
            callForFailure " Version number is not incremented. Requested app Version number ($pListVersionNumber) < Old app version number ($version)"
        fi
    else
        echo "Version numbers that are provided in the form and the Info.plist of the project does not match."
        echo "Plist version count:$versionCount Doc version count:$docVersonCount"
        echo "Current Plist version number:$pListVersionNumber"
        echo "Previous Plist version number:$version"
        callForFailure "Requested app Version number and the Old app version number does not match. Requested app version count:$versionCount Old app version count:$docVersonCount. Requested app version number:$pListVersionNumber. Old app version number:$version"
    fi
}

function versionCheckShortStringAvailable() {
	pListVersionNumberShortString=$(/usr/libexec/PlistBuddy -c "print :CFBundleShortVersionString" "$1") && versionCheckShortString $1 || callForFailure "Could not find Version Number in Plist file."
}

function versionCheckShortString() {
    echo "$pListVersionNumberShortString">>"$CURRENT_PARAMETER_LOCATION"
    echo "$pListVersionNumberShortString">>"$CURRENT_ALT_PARAMETER_LOCATION"

    IFS="." read -a arrayVersionNumber <<< "$pListVersionNumberShortString" || callForFailure "Version Number format $pListVersionNumberShortString is in improper format. Please follow this format *.*.* i.e. for example 1.0.1"
    versionCount="${#arrayVersionNumber[@]}" || callForFailure "Version Number Short String format $pListVersionNumberShortString is in improper format. Please follow this format *.*.* i.e. for example 1.0.1"
    if [ "$versionShortString" = "" ]; then
        versionShortString="1"
        for (( i=1; i<$versionCount; i++ ))
        do
            versionShortString=$versionShortString".0"
        done
    fi
    IFS="." read -a arrayDocVersionNumber <<< "$versionShortString" || callForFailure "Internal error in reading old Version Number Short String $versionShortString. Please check with admin: mobileapp@nike.com."
    docVersonCount="${#arrayDocVersionNumber[@]}" || callForFailure "Internal error in reading old Version Number Short String $versionShortString. Please check with admin: mobileapp@nike.com."
    if [ "$versionCount" -gt "$docVersonCount" ]; then
        for (( i=$docVersonCount; i<$versionCount; i++ ))
        do
            versionShortString=$versionShortString".0"
        done
        docVersonCount="$versionCount"
    else
        difference=$(( ${docVersonCount} - ${versionCount} ))
        for (( j=0; j<$difference; j++ ))
        do
            arrayVersionNumber[$versionCount+$j]='0' || callForFailure "$1 Unable to process pList Version Number Short String $pListVersionNumberShortString and old Version Number Short String $versionShortString"
        done
        versionCount=$(( $versionCount + ${difference} )) || callForFailure "$1 Unable to process pList Version Number Short String $pListVersionNumberShortString and old Version Number Short String $versionShortString"
    fi
    echo "the size of array arrayVersionNumber $versionCount"
    IFS="." read -a arrayDocVersionNumber <<< "$versionShortString" || callForFailure "$1 Unable to process pList Version Number Short String $pListVersionNumberShortString and old Version Number Short String $versionShortString"
    if [ "$versionCount" -eq "$docVersonCount" ]; then
        isIncremented=false
        isEqual=false
        for (( i=1; i<=$versionCount; i++ ))
        do
            vDN=${arrayDocVersionNumber[$i-1]} || callForFailure "accessing the arrayDocVersionNumber with position $i-1"
            vN=${arrayVersionNumber[$i-1]} || callForFailure "accessing the arrayVersionNumber with Position $i-1"
            valueChecked=$(isInteger "$vN") || callForFailure "isInteger method call with parameters $vN"
            #Check whether the call is for Version increment as part of Profile Renewal maintenance or just for signing the app
            if [ "$valueChecked" = "Not an Integer" ]; then
                callForFailure "Version Number Short String have text. Improper Version Number Short String format."
            else
                if [ $vN -ge $vDN ]; then
                    if [ $vN -gt $vDN ]; then
                        isIncremented=true
                        isEqual=false
                        break
                    else
                        isEqual=true
                        isIncremented=false
                    fi
                else
                    callForFailure "Version number Short String is not incremented. Version is $versionShortString and PListVersion short string is $pListVersionNumberShortString"
                fi
            fi
        done
        if [ "$isIncremented" = true ]; then
            echo "Version number short string is incremented. Requested app Version number Short String ($pListVersionNumberShortString) > Old app version number Short String ($versionShortString)"
#        elif [ "$isEqual" = true ]; then
#            echo "Version number short string is not incremented. But Requested app Version number Short String ($pListVersionNumberShortString) = Old app version number Short String ($versionShortString)"
        else
             echo "Version number is not incremented. Requested app Version number ($pListVersionNumberShortString) < Old app version number ($versionShortString)"
            callForFailure " Version number is not incremented. Requested app Version number ($pListVersionNumberShortString) < Old app version number ($versionShortString)"
        fi
    else
        echo "Version numbers that are provided in the form and the Info.plist of the project does not match."
        echo "Plist version count:$versionCount Doc version count:$docVersonCount"
        echo "Current Plist version number short string:$pListVersionNumberShortString"
        echo "Previous Plist version number short string:$versionShortString"
        callForFailure "Requested app Version Number Short String and the Old app Version Number Short String does not match. Requested app version count:$versionCount Old app version count:$docVersonCount. Requested app Version Number Short String:$pListVersionNumberShortString. Old app Version Number Short String:$versionShortString"
    fi
}

function processLabel() {
    IFS="." read -a arrayString <<< "$1" || callForFailure "Unable to process app label $1"
    result=""
    isCom=false
    isAfterNike=false
    isSequence=false
    isNike=false
    nikePosition=-1
    for (( i=0; i<"${#arrayString[@]}"; i++ ))
    do
        if [ "${arrayString[i]}" = "nike" ]; then
            isNike=true
            nikePosition=$i
        fi
        if [ "${arrayString[i]}" = "com" ]; then
            isCom=true
            result="${arrayString[i]}" || callForFailure "Unable to process app label at com.: $1"
        elif [ "$isCom" = true ]; then
            result="$result.nike" || callForFailure "Unable to process app label at com.nike.: $1"
            isCom=false
            isAfterNike=false
            isSequence=true
        elif [ "$isAfterNike" = true ]; then
            isAfterNike=false
            result="$result.RetailBrandiPhone" || callForFailure "Unable to process app label after com.nike.: $1"
        else
            if [ $i = 0 ]; then
                result="${arrayString[i]}" || callForFailure "Unable to process app label from start: $1"
            else
                result="$result.${arrayString[i]}" || callForFailure "Unable to process app label tail: $1"
            fi
        fi
    done
#If bundle is not in a  proper format such as not like "com.nike." but like "eg: "es.digiworks.nike.su14.mensathletic " it will process it to get the correct format
    if [ "$isSequence" = false ]; then
        result=""
        isNikeReached=false
        if [ "$nikePosition" -gt -1 ]; then
            for (( i=0; i<"${#arrayString[@]}"; i++ ))
            do
                if [ "$nikePosition" -eq 0 ]; then
                    isNikeReached=true
                    result="com.nike"
                elif [ "$nikePosition" -eq "$(( $i + 1 ))" ]; then
                    isNikeReached=true
                    result="com"
                elif [ "$isNikeReached" = true ]; then
                    result="$result.${arrayString[i]}"
                fi
            done
        else
            result="com.nike.$1"
        fi
    fi
#	if [ "$result" = "com.nike.VRLink-Nike" ]; then
#    	result="com.nike.wholesale.golf.VRLink"
#    fi
    echo $result
}

function bundleIDCheck() {
    pListBundleID=$(/usr/libexec/PlistBuddy -c "print :CFBundleIdentifier" "$1") || callForFailure "CFBundleIdentifier is missing app. Please check with your tech team and have it fixed."
    pListAppTitle=$(/usr/libexec/PlistBuddy -c "print :CFBundleDisplayName" "$1") || callForFailure "CFBundleDisplayName is missing in your app. Please check with your tech team and have it fixed. "
    finalBundleID=$(processLabel "$pListBundleID") || callForFailure "Unable to process Bundle ID: $pListBundleID Please check with your tech team and have it fixed."
    echo "Final edited bundle id is $finalBundleID"
    echo "$finalBundleID">>"$CURRENT_PARAMETER_LOCATION"
    echo "$finalBundleID">>"$CURRENT_ALT_PARAMETER_LOCATION"
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier '${finalBundleID}'" "$1" || callForFailure "Unable to update Bundle ID to $finalBundleID. Please contact mobileapps@nike.com"
    bundleName=$(/usr/libexec/PlistBuddy -c "print :CFBundleName" "$1") || callForFailure "CFBundleName is missing in your app. Please check with your tech team and have it fixed and Resubmit."
    echo "$bundleName">>"$CURRENT_ALT_PARAMETER_LOCATION"
}

function minOSVersion() {
    pListminOSVersion=$(/usr/libexec/PlistBuddy -c "print :MinimumOSVersion" "$1") || callForFailure "Unable to read MinimumOSVersion of your app. Please check with your tech team and have it fixed and Resubmit."
}

#function bundleIDCheck() {
#pListBundleID=$(/usr/libexec/PlistBuddy -c "print :CFBundleIdentifier" "$1") || callForFailure "Failed to read Bundle ID."
#IFS="." read -a arrayBundleID <<< "$pListBundleID" || callForFailure "Splitting the Bundle ID against ."
#if [ ${arrayBundleID[1]} != "nike" ]; then
#echo "Improper format of Bundle ID i.e. nike is missing: $pListBundleID"
#finalBundleID=${arrayBundleID[0]}".nike.RetailBrandiPhone" || callForFailure "Getting the bundle ID from PList"
#for (( i=3; i<"${#arrayBundleID[@]}"; i++ ))
#do
#finalBundleID=$finalBundleID"."${arrayBundleID[$i]} || callForFailure "Changing the Bundle ID inside PList"
#done
#echo "Final edited bundle id is $finalBundleID"
#/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier '${finalBundleID}'" "$1" || callForFailure "Printing and seeting the bundle identifier from Plist"
#else
#finalBundleID=${arrayBundleID[0]}".nike.RetailBrandiPhone" || callForFailure "Getting the bundle ID from PList"
#for (( i=3; i<"${#arrayBundleID[@]}"; i++ ))
#do
#finalBundleID=$finalBundleID"."${arrayBundleID[$i]} || callForFailure "Changing the Bundle ID inside PList"
#done
#echo "Final edited bundle id is $finalBundleID"
#echo "Proper format of Bundle ID with nike: $pListBundleID"
#fi
#}

function editPListFile() {
	versionCheckShortStringAvailable "$1" &&
    versionCheck "$1" &&
    bundleIDCheck "$1" &&
    minOSVersion "$1" ||
    callForFailure "Unable to do either versionCheckShortStringCheck or versionCheck or bundleIDCheck or minOSVersionCheck $1"
}

function processAPPFile() {
    cd "$1" || callForFailure "changing the directory to $1"
    for k in *.plist; do
        if [ "$k" = "Info.plist" ]; then
            editPListFile "$k" || callForFailure "Unable to edit pList file $k"
            break
        fi
    done
}

function findAPPs() {
    echo ">>>>>>>>>>>>>>>>>>>>>>>>  Finding the app file...     <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    cd Payload || callForFailure "Changing the directory to Payload"
    find ./ -type d \( -name "*.app" \) || callForFailure "Finding the directories type name"
    aPPFiles=$(find . -type d \( -name "*.app" \)|wc -l) || callForFailure "Missing .app file/name. Please validate  ipa build with your tech team."
    if [ $aPPFiles -eq 0 ] ; then
        callForFailure "******The APP file is missing.*******"
    else
        echo "Number of APP files found " $aPPFiles
        aPPFileName=$(find . -type d \( -name "*.app" \)) || callForFailure "Missing .app file/name. Please validate  ipa build with your tech team."
        echo "Name of the APP file is -->  $aPPFileName"
        processAPPFile "$aPPFileName" || callForFailure "processAPPFile $aPPFileName was failed. Please check with admin: mobileapp@nike.com."
    fi
}

isValidNewFolder=false
function checkIfIPAExistsInNewFolder() {
    for i in New/*.ipa; do
        isValidNewFolder=true
    done
}

function createNewFolder() {
pwd
    if [ -d "New" ]; then
        if [ -d "Old" ]; then
            rm -rf Old || callForFailure "Unable to clean Oldest files. Please check with admin: mobileapp@nike.com."
        fi
        echo "Moving content of existing New folder to Old folder"
        mkdir Old || callForFailure "Unable to save apps old version files. Please check with admin: mobileapp@nike.com."
        chmod 777 Old
        NewContent=$(ls New/ | wc -l)
        echo "New content size $NewContent"
        if [ $NewContent -gt 0 ]; then
            checkIfIPAExistsInNewFolder
            if [ $isValidNewFolder = true ]; then
                mv New/* Old || callForFailure "Unable to Save apps old version files. Please check with admin: mobileapp@nike.com."
            else
                rm -rf New || callForFailure "Unable to clean the new apps directory. Please check with admin: mobileapp@nike.com."
                mkdir New || callForFailure "Unable to create folder for lates apps files. Please check with admin: mobileapp@nike.com."
                chmod 777 New
            fi
        fi
    else
        mkdir New || callForFailure "Unable to create folder for lates apps files. Please check with admin: mobileapp@nike.com."
        chmod 777 New
    fi
    chmod 777 "$file" || echo "failed to change permissions of $file."
    destination="$CURRENT_PROJECTS/$1/New"
    source="$CURRENT_PROJECT/$file/*"
    alternateSource="$CURRENT_PROJECT/*"
    cd "$CURRENT_PROJECT" || callForFailure "Unable to switch directories. Please check with admin: mobileapp@nike.com."
    for i in * ; do
        chmod 777 "$i" || echo "Unable to alter directory permissions $i. Please check with admin: mobileapp@nike.com."
    done
    cd Payload || callForFailure "Unable to switch director Payload. Please check with admin: mobileapp@nike.com."
    for i in * ; do
        chmod 777 "$i" || echo "Unable to alter directory permissions $i. Please check with admin: mobileapp@nike.com."
    done
    echo "Moving $source to $destination"
    mv $source $destination || mv $alternateSource $destination || callForFailure "Unable to save files at new location. Please check with admin: mobileapp@nike.com."
    
}

function createNewProject() {
    echo "Project name is $1"
    if [ "$1" = "" ]; then
        callForFailure "Project name is not available or not specified"
    else
        if [ -d "$1" ]; then
            cd "$1" || callForFailure "change directory to $1"
        else
            mkdir "$1" || callForFailure "Make directory named $1"
            chmod 777 "$1" || echo "failed to change permissions of $1."
            cd "$1" || callForFailure "change directory to $1"
        fi
        createNewFolder "$1" || callForFailure "createNewFolder method call with parameter $1"
    fi
}

function createProject() {
    if [ -d "Projects" ]; then
        cd Projects || callForFailure "change directory to Project"
    else
        mkdir Projects || callForFailure "Make directory named Projects"
        cd Projects || callForFailure "change directory to Projects"
    fi
    createNewProject "$appName" || callForFailure "createNewProject method call"
}

function moveFiles() {
    cd "$CURRENT_WORKSPACE" || callForFailure "change directory to workspace"
    createProject || callForFailure "createProject method call"
}

counter=0
appRequest=""
projectName=""
appName=""
isReturn=false
isProjectType=false
projectType=""
isIPA=false
ipaExist=false
ipaFileName=""
isFolder=false
folderExist=false
isBundleID=false
counter=-1
version=""
isUrl=false
urlParameters=""
isPushStar=false
isPush=false
isClientUrl=false
IsRenew=false
doRenew=false
CLIENT_URL="http://mobileappstdev.nike.com:8090/ApplicationSubmission/Public/UpdateJobResult"

printEmptyLines

while read parameters; do
    if [ "$parameters" = "*BUNDLE_ID*" ]; then
        isBundleID=true
    elif [ $isBundleID = true ]; then
        BUNDLE_ID="$parameters"
        isBundleID=false
    elif [ "$parameters" = "*CLIENT_URL*" ]; then
        isClientUrl=true
    elif [ $isClientUrl = true ]; then
        CLIENT_URL="$parameters"
        isClientUrl=false
    elif [ "$parameters" = "*ProjectType*" ]; then
        isProjectType=true
    elif [ $isProjectType = true ]; then
        projectType="$parameters"
        isProjectType=false
    elif [ "$parameters" = "*IPA*" ]; then
        isIPA=true
    elif [ $isIPA = true ]; then
        ipaExist="$parameters"
        isIPA=false
        ipaExist=true
    elif [ $ipaExist = true ]; then
        ipaExist=false
        ipaFileName="$parameters"
    elif [ "$parameters" = "*Folder*" ]; then
        isFolder=true
    elif [ $isFolder = true ]; then
        isFolder=false
        folderExist="$parameters"
        echo "folderExist $parameters"
        isUrl=true
    elif [ $isUrl = true ]; then
        urlParameters="$parameters"
        isUrl=false
    elif [ $counter -eq -1 ]; then
        counter=0
        echo " -1 $parameter"
    elif [ "$parameters" = "*isPush*" ]; then
        isPushStar=true
    elif [ $isPushStar = true ]; then
        isPush=$parameters
        isPushStar=false
    elif [ $counter -eq 0 ]; then
        counter=1
        appRequest="$parameters"
        echo "appRequest $appRequest"
    elif [ $counter -eq 1 ]; then
        counter=2
        versionParameter="$parameters"
        IFS="^" read -a versionArrayString <<< "$versionParameter"
        version="${versionArrayString[0]}"
        versionShortString="${versionArrayString[1]}"
        echo "version $version"
    elif [ $counter -eq 2 ]; then
        counter=3
        appName="$parameters"
        appName=$(echo ${appName// /_})
        echo "appName $appName"
    elif [ $counter -eq 3 ]; then
        counter=4
        projectName="$parameters"
        projectName=$(echo ${projectName// /_})
        echo "Project Name $projectName"
    else
        file="$parameters"
#      isReturn=true
    fi
done < "$CURRENT_PARAMETER_LOCATION" || callForFailure "reading the parameters"

echo "CLIENT_URL: $CLIENT_URL"
cp "$CURRENT_PARAMETER_LOCATION" ../parameters.txt || callForFailure "Making a copy of the parameters file at one level above"
chmod 777 ../parameters.txt || echo "Changing the permissions of the parameters.txt"



findAPPs || callForFailure "findApps method call"
moveFiles || callForFailure "moveFiles method call at line 235"
Result="Current Bundle Version number Short string ($pListVersionNumberShortString) > Old version ($versionShortString).<br>Current Bundle Version ($pListVersionNumber) > Old version ($version)<br>Bundle Id is $finalBundleID<br>MinOSVersion is $pListminOSVersion"
Result=$(echo "$Result" | sed -e "s/ /%20/g")


 if [[ "$appRequest" == "New App" ]] || [[ "$appRequest" == "Update Existing App" ]] 
 then
 	echo "$appRequest, checking if Bundle ID is available or not."
 	URL="https://mobileappssign.nike.com:8443/ApplicationSubmission/Private/IsBundleIDAvailable?AppBundleID=$finalBundleID&RequestType=$appRequest&AppTitle=$appName&MI_AppTitle=$pListAppTitle"
	URL=$(echo "$URL" | sed -e "s/ /%20/g")
	response=$(curl -s "$URL") || $(echo "false");
	if [[ $response == *"false"* ]]; then
  		callForFailure " The bundle id $finalBundleID is already been taken by another project. Please use a different Bundle ID.".
	else
		CLIENT_URL="$CLIENT_URL$urlParameters&Result=$Result&AppCurrentVersion=$pListVersionNumber&AppCurrentVersionShortString=$pListVersionNumberShortString"
		echo "$CLIENT_URL"
		curl -s "$CLIENT_URL" || callForFailure "Updating the status to the server with a curl call"
		printEmptyLines
	fi
 else
 	CLIENT_URL="$CLIENT_URL$urlParameters&Result=$Result&AppCurrentVersion=$pListVersionNumber&AppCurrentVersionShortString=$pListVersionNumberShortString"
	echo "$CLIENT_URL"
	curl -s "$CLIENT_URL" || callForFailure "Updating the status to the server with a curl call"
	printEmptyLines
fi


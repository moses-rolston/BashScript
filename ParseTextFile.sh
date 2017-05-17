#!/bin/bash

JENKINS_WORK_SPACE="/Users/a.appsubmission/.jenkins/jobs/UnZipProcess/workspace"

SHARED_DISK_VOLUME="/Volumes/Projects/MobileApps/Test"

CURRENT_WORKSPACE="$SHARED_DISK_VOLUME"
CURRENT_PROJECT="$CURRENT_WORKSPACE/project"
CURRENT_PARAMETER_LOCATION="$CURRENT_PROJECT/parameters.txt"
CURRENT_ALT_PARAMETER_LOCATION="$CURRENT_WORKSPACE/parameters.txt"
CURRENT_PROJECTS="$CURRENT_WORKSPACE/Projects"

NEW_APP=false
UPDATE_EXISTING_APP=false
REMOVE_APP_FROM_STORE=false
IS_IPAD=false
IS_IPHONE=false
isX=false
IS_BUSINESS_OWNER=false
BO_NAME=""
BO_TITLE=""
BO_DEPT=""
BO_EMAIL=""
BO_PHONE=""
IS_TECHNICAL_SUPPORT_CONTACT=false
TSC_NAME=""
TSC_TITLE=""
TSC_DEPT=""
TSC_EMAIL=""
TSC_PHONE=""
IS_APPLICATION_INFORMATION=FALSE

isName=false
isTitle=false
isDept=false
isEmail=false
isPhone=false

isAppTitle=false
isDescription=false
isVersion=false
isMinOperatingSystem=false
isSecurity=false
isLabel=false
isADGroupLabel=false

isGoLiveDate=false
goLiveDate=""
isRemovalDate=false
removalDate=""
isRightHandParsingDone=false

function printEmptyLines() {
    echo " "
    echo " "
    echo " "
}

function callForFailure() {
    Result="Failed to execute the command at $1"
    echo "$Result"
    Result=$(echo "$Result" | sed -e "s/ /%20/g")
    CLIENT_URL="$CLIENT_URL$urlParameters&Result=$Result"
    curl -s "$CLIENT_URL"
    echo " !!!!!!!!!!!!!!! Failure !!!!!!!!!!!!!!!!!!!!!" && printEmptyLines && cd error
    exit
}

isReturn=false
isProjectType=false
isIPA=false
ipaExist=false
isFolder=false
folderExist=false
isUrl=false
urlParameters=""
isPush=false
isClientUrl=false

while read parameters; do
    echo $parameters
    if [ "$parameters" = "*CLIENT_URL*" ]; then
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
        isUrl=true
    elif [ $isUrl = true ]; then
        urlParameters="$parameters"
        echo $urlParameters
        isUrl=false
    else
        file="$parameters"
#isReturn=true
    fi
done < "$CURRENT_PARAMETER_LOCATION" || callForFailure "reading the parameters"

echo "CLIENT_URL: $CLIENT_URL"

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

function callForX() {
    if [ "$1" = "New App" ]; then
        NEW_APP=true
        isX=false
    elif [ "$1" = "Update Existing App" ]; then
        UPDATE_EXISTING_APP=true
        isX=false
    elif [  "$1" = "Remove App from Appstore" ]; then
        REMOVE_APP_FROM_STORE=true
        isX=false
    elif [ "$1" = "iPad" ]; then
        IS_IPAD=true
        iPhoneOrIpodValue="$1"
        isX=false
    elif [ "$1" = "iPhone" -o "$1" = "/iPod" ]; then
        IS_IPHONE=true
        iPhoneOrIpodValue="$iPhoneOrIpodValue $1"
    fi
}

function resetBooleanValues() {
    isName=false
    isTitle=false
    isDept=false
    isEmail=false
    isPhone=false
    isPush=false
}

function callForBusinessOwner() {

    if [ "$1" = "Name" ]; then
        isName=true
        isPhone=false
    elif [ "$1" = "Title" ]; then
        isTitle=true
        isName=false
    elif [ "$1" = "Dept" ]; then
        isDept=true
        isTitle=false
    elif [ "$1" = "E-Mail" ]; then
        isEmail=true
        isDept=false
    elif [ "$1" = "Phone" ]; then
        isPhone=true
        isEmail=false
    elif [ "$1" = "Technical Support Contact" ]; then
        isPhone=false
        IS_BUSINESS_OWNER=false
        IS_TECHNICAL_SUPPORT_CONTACT=true
    elif [ "$isName" = true ]; then
        BO_NAME="$BO_NAME $1"
    elif [ "$isTitle" = true ]; then
        BO_TITLE="$BO_TITLE $1"
    elif [ "$isDept" = true ]; then
        BO_DEPT="$BO_DEPT $1"
    elif [ "$isEmail" = true ]; then
        BO_EMAIL="$BO_EMAIL$1"
    elif [ "$isPhone" = true ]; then
        BO_PHONE="$BO_PHONE$1"
    fi
}

function callForTechnicalSupportContact() {
    if [ "$1" = "Name" ]; then
        isName=true
        isPhone=false
    elif [ "$1" = "Title" ]; then
        isTitle=true
        isName=false
    elif [ "$1" = "Dept" ]; then
        isDept=true
        isTitle=false
    elif [ "$1" = "E-Mail" ]; then
        isEmail=true
        isDept=false
    elif [ "$1" = "Phone" ]; then
        isPhone=true
        isEmail=false
    elif [ "$p" = "Application Information" ]; then
        isPhone=false
        IS_TECHNICAL_SUPPORT_CONTACT=false
        IS_APPLICATION_INFORMATION=true
    elif [ "$isName" = true ]; then
        TSC_NAME="$TSC_NAME $1"
    elif [ "$isTitle" = true ]; then
        TSC_TITLE="$TSC_TITLE $1"
    elif [ "$isDept" = true ]; then
        TSC_DEPT="$TSC_DEPT $1"
    elif [ "$isEmail" = true ]; then
        TSC_EMAIL="$1"
    elif [ "$isPhone" = true ]; then
        TSC_PHONE="$TSC_PHONE$1"
    fi
}

function callForApplicationInformation() {
    if [ "$1" = "App Title" ]; then
        isADGroupLabel=false
        isAppTitle=true
    elif [ "$1" = "Description" ]; then
        isAppTitle=false
        isDescription=true
    elif [ "$1" = "Version" ]; then
        isVersion=true
        isDescription=false
    elif [ "$1" = "Min. Operating System" ]; then
        isMinOperatingSystem=true
        isVersion=false
    elif [ "$1" = "Security Level" ]; then
        isSecurity=true
        isMinOperatingSystem=false
    elif [ "$1" = "AD Group" ]; then
        isLabel=true
        isSecurity=false
        isMinOperatingSystem=false
    elif [ "$1" = "Label" -a "$isLabel" = true ]; then
        isADGroupLabel=true
        isLabel=false
    elif [ "$1" = "Does your application contain Entitlements?" ]; then
        IS_APPLICATION_INFORMATION=false
        isADGroupLabel=false
    elif [ "$1" = "Supported Devices" ]; then
        IS_APPLICATION_INFORMATION=false
        isADGroupLabel=false
    elif [ "$isAppTitle" = true ]; then
        appTitle="$appTitle$1"
    elif [ "$isDescription" = true ]; then
        description="$description$1"
    elif [ "$isVersion" = true ]; then
        version="$version$1"
    elif [ "$isMinOperatingSystem" = true ]; then
        if [ "$1" = "Label" ]; then
            isADGroupLabel=true
            isMinOperatingSystem=false
        else
            minOperatingSystem="$minOperatingSystem$1"
        fi
    elif [ "$isSecurity" = true ]; then
        security="$security$1"
    elif [ "$isADGroupLabel" = true ]; then
        if [ "$1" == "isPush" ]; then
            isADGroupLabel=false
            isPush=true
            echo "isPush starts...."
        else
            adGroupLabel="$adGroupLabel$1"
        fi
    elif [ "$isPush" = true ]; then
        isPush="$1"
        IS_APPLICATION_INFORMATION=false
        echo "*isPush*">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing removal to parameters"
        echo "$isPush">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing removal to parameters"
    fi
}

function printAppRequestData() {
    echo " "
    appRequest="Application request: "
    if [ "$NEW_APP" = true ]; then
        appRequest=$appRequest"New App"
        echo "New App">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing new app data to parameters"
    elif [ "$UPDATE_EXISTING_APP" = true ]; then
        appRequest=$appRequest"Update Existing App"
        echo "Update Existing App">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing Update Existing App to parameters"
    elif [ "$REMOVE_APP_FROM_STORE" = true ]; then
        appRequest=$appRequest"Remove App from Appstore"
        echo "Remove App from Appstore">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing removal to parameters"
    fi
    echo $appRequest
    echo " "
}

function printDates() {
    echo "Go-Live Date: "$goLiveDate
    echo "Removal Date: "$removalDate
    echo " "
}

function printBusinessOwnerData() {
    echo "Business Owner Name: $BO_NAME"
    echo "Business Owner Title: $BO_TITLE"
    echo "Business Owner Dept: $BO_DEPT"
    echo "Business Owner Email: $BO_EMAIL"
    echo "Business Owner Phone: $BO_PHONE"
    echo " "
}

function printTechnicalSupportContactData() {
    echo "Technical Support Contact Name: $TSC_NAME"
    echo "Technical Support Contact Title: $TSC_TITLE"
    echo "Technical Support Contact Dept: $TSC_DEPT"
    echo "Technical Support Contact Email: $TSC_EMAIL"
    echo "Technical Support Contact Phone: $TSC_PHONE"
    echo " "
}


function printApplicationInformationData() {
    echo "Application Title: $appTitle"
    echo " "
    echo "Application Description: $description"
    echo " "
    echo "Application Version: $version"
    echo "$version">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing version number to parameters file"
    echo "Application Min. Operating System: $minOperatingSystem"
    if [ "$security" = "Gold" -o  "$security" = "gold" -o "$security" = "GOLD" ]; then
        echo "Application Security Level: $security"
    elif [ "$security" = "Silver" -o  "$security" = "silver" -o "$security" = "SILVER" ]; then
        echo "Application Security Level: $security"
    elif [ "$security" = "Bronze" -o  "$security" = "bronze" -o "$security" = "BRONZE" ]; then
        echo "Application Security Level: $security"
    else
        echo "Application Security Level: $security"
    fi
    echo "Application ADG Group Label: $adGroupLabel"
    echo " "
    echo "$appTitle">>"$CURRENT_PARAMETER_LOCATION" || callForFailure "writing the application title to parameters file"
}

function printSupportedDevicesData() {
    support="Supported Devices:  $iPhoneOrIpodValue"
    echo $support
    echo " "
    echo "isPush $isPush"
}

function printData() {
    printAppRequestData || callForFailure "printing App request data"
    printDates || callForFailure "printing dates"
    printBusinessOwnerData || callForFailure "Business owner data"
    printTechnicalSupportContactData || callForFailure "Technical Support data"
    printApplicationInformationData || callForFailure "Application Information"
    printSupportedDevicesData || callForFailure "Printing supported devices data"
}

function parseFile() {
    resetBooleanValues
    while read p; do
        if [ "$p" = "X" ] || [ "$p" = "x" ] ; then
        	echo $p
            isX=true
        elif [ "$isX" = true ] ; then
            callForX "$p" || callForFailure "call for X method"
        elif [ "$p" = "Business Owner" ]; then
            IS_BUSINESS_OWNER=true
        elif [ "$IS_BUSINESS_OWNER" = true ]; then
            callForBusinessOwner "$p" || callForFailure "Business owner method"
        elif [ "$p" = "Technical Support Contact" ]; then
            IS_TECHNICAL_SUPPORT_CONTACT=true
        elif [ "$IS_TECHNICAL_SUPPORT_CONTACT" = true ]; then
            callForTechnicalSupportContact "$p" || callForFailure "Technical support contact method"
        elif [ "$p" = "Application Information" ]; then
            IS_APPLICATION_INFORMATION=true
        elif [ "$IS_APPLICATION_INFORMATION" = true ]; then
            callForApplicationInformation "$p" || callForFailure "call for application information method"
        fi
        if [ "$isRightHandParsingDone" = false ]; then
            if [ "$p" = "New App" ]; then
                isGoLiveDate=true
            elif [ "$p" = "Go-Live Date" ]; then
                isGoLiveDate=false
            elif [ "$isGoLiveDate" = true ]; then
                goLiveDate="$goLiveDate$p"
            elif [ "$p" = "Update Existing App" ]; then
                isRemovalDate=true
            elif [ "$p" = "Removal Date" ]; then
                isRemovalDate=false
                isRightHandParsingDone=true
            elif [ "$isRemovalDate" = true ]; then
                removalDate="$removalDate$p"
            fi
        fi
    done < WordToText.txt || callForFailure "reading the text file"
    printData
}

function errorCheckForDoc() {
    if [ "$NEW_APP" = false ]; then
        if [ "$UPDATE_EXISTING_APP" = false ];  then
            if [ "$REMOVE_APP_FROM_STORE" = false ]; then
                echo "No proper selection made for this request (New App, Update, Remove)"
                callForFailure "inside error check, no request type."
            fi
        fi
    fi
}

if [ "$isReturn" = true ]; then
    echo "continue...."
    Result="Parse your request. Continue..."
    Result=$(echo "$Result" | sed -e "s/ /%20/g")
    CLIENT_URL="$CLIENT_URL$urlParameters&Result=$Result"
    curl -s "$CLIENT_URL" || callForFailure "Updating the status to the server with a curl call"
    printEmptyLines
else
    for i in *.txt ; do
    	if [ "$i" != "parameters.txt" ]; then
	        printEmptyLines
	        echo ">>>>>>>>>>    Parsing of $i is in process. Please wait... <<<<<<<<<<<<"
	        parseFile || callForFailure "parseFile"
	        errorCheckForDoc || callForFailure "erroCheckForDoc"
	        isX=false
	        Result="Parsing your request is successful."
	        Result=$(echo "$Result" | sed -e "s/ /%20/g")
	        CLIENT_URL="$CLIENT_URL$urlParameters&Result=$Result"
	        echo "$CLIENT_URL"
	        curl -s "$CLIENT_URL" || callForFailure "Updating the status to the server with a curl call"
	        printEmptyLines
	        break
	    fi
    done
fi


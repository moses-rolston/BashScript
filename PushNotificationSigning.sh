#!/bin/bash

JENKINS_WORK_SPACE="/Users/a.appsubmission/.jenkins/jobs/UnZipProcess/workspace"

SHARED_DISK_VOLUME="/Volumes/Projects/MobileApps/Production"

CURRENT_WORKSPACE="$SHARED_DISK_VOLUME"
CURRENT_PROJECT="$CURRENT_WORKSPACE/project"
CURRENT_PARAMETER_LOCATION="$CURRENT_PROJECT/parameters.txt"
CURRENT_ALT_PARAMETER_LOCATION="$CURRENT_WORKSPACE/parameters.txt"
CURRENT_PROJECTS="$CURRENT_WORKSPACE/Projects"

CLIENT_URL="http://localhost:8090/ApplicationSubmission/Public/UpdateJobResult"
PROFILE_DESTINATION="$CURRENT_WORKSPACE/PushNotificationProfiles"
LATEST_PUSH_SIGN_APP="$CURRENT_WORKSPACE/ProvisioningProfiles/./latest_push_sign_app.sh"
GENERIC_NIKE_PROFILE="$CURRENT_WORKSPACE/ProvisioningProfiles/Generic_Nike.mobileprovision"
PRODUCTION_SIGNING_IDENTITY="iPhone Distribution: Nike, Inc./"
ENTERPRISE_SIGNING_IDENTITY="iPhone Distribution: Nike, Inc"

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

function checkStatus {
	if [ $? -ne 0 ];
	then
		echo "Had an Error, aborting!"
		exit 1
	fi
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


counter=0
appRequest=""
projectName=""
APP_NAME=""
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
bundleVersionValue=""
bundleIDValue=""
isPushStar=false
isPush=false
isClientUrl=false

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
        isUrl=true
    elif [ $isUrl = true ]; then
        urlParameters="$parameters"
        echo $urlParameters
        isUrl=false
    elif [ $counter -eq -1 ]; then
        counter=0
    elif [ "$parameters" = "*isPush*" ]; then
        isPushStar=true
    elif [ $isPushStar = true ]; then
        isPush=$parameters
        isPushStar=false
    elif [ $counter -eq 0 ]; then
        counter=1
        appRequest="$parameters"
    elif [ $counter -eq 1 ]; then
        counter=2
        version="$parameters"
    elif [ $counter -eq 2 ]; then
        counter=3
        APP_NAME="$parameters"
        APP_NAME=$(echo ${APP_NAME// /_})
    elif [ $counter -eq 3 ]; then
        counter=4
        projectName="$parameters"
        projectName=$(echo ${projectName// /_})
        echo "Project Name $projectName"
    elif [ $counter -eq 4 ]; then
        counter=5
        bundleVersionValue="$parameters"
    elif [ $counter -eq 5 ]; then
        counter=6
        bundleIDValue="$parameters"
    else
        file="$parameters"
#isReturn=true
    fi
done < "$CURRENT_ALT_PARAMETER_LOCATION" || callForFailure "reading the parameters"

echo "CLIENT_URL: $CLIENT_URL"
PAYLOAD="Projects/$APP_NAME/New/Payload"
printEmptyLines
cd "$PAYLOAD" || callForFailure "Changing the directory at lin 138"

# Check for and resign any embedded frameworks (new feature for iOS 8 and above apps)
if [[ "$APP_NAME" == "Capacity_Planning" ]] || [[ "$APP_NAME" == "Europe_CGP" ]]
then
	echo "Skipped signing of app frameworks for app named $APP_NAME."
else
	for i in *.app; do
		FRAMEWORKS_DIR="$i/Frameworks"
		echo "Framework directory is: $FRAMEWORKS_DIR" 
		if [ -d "$FRAMEWORKS_DIR" ];
		then
			echo "Resigning embedded frameworks."
			for framework in "$FRAMEWORKS_DIR"/*
			do
				if [[ "$framework" == *.framework ]] || [[ "$framework" == *.dylib ]]
				then
					#echo "Signing the framework: $framework"
					#codesign -f -s "$ENTERPRISE_SIGNING_IDENTITY" "$framework"
					#checkStatus
					 if [ "$isPush" = false ]; then
	        			echo "Signing the framework: $framework"
	        			../../../../ProvisioningProfiles/./latest_push_sign_app.sh -t enterprise -p "$GENERIC_NIKE_PROFILE" -a "$framework" -e ../Entitlements.xml || ../../../../ProvisioningProfiles/./latest_push_sign_app.sh -t enterprise -p "$GENERIC_NIKE_PROFILE" -a "$framework" || callForFailure "Signing of the app failed"
	    			else
	        			profilePath="Push notification signing with profile:  $PROFILE_DESTINATION/$APP_NAME.mobileprovision"
	        			echo "Signing the framework: $framework: $profilePath"
	        			../../../../ProvisioningProfiles/./latest_push_sign_app.sh -t enterprise -p $PROFILE_DESTINATION/$APP_NAME.mobileprovision -a "$framework" -e ../Entitlements.xml || ../../../../ProvisioningProfiles/./latest_push_sign_app.sh -t enterprise -p "$GENERIC_NIKE_PROFILE" -a "$framework" || callForFailure "Push Notification Signing failed"
	   				 fi
	   				 checkStatus
				else
					echo "Ignoring non-framework: $framework"
				fi
			done
		else
			echo "$FRAMEWORKS_DIR is not a directory."
		fi
	done
fi

for i in *.app; do
    if [ "$isPush" = false ]; then
        echo "Normal signing with profile : Generic_Nike.mobileprovision"
        ../../../../ProvisioningProfiles/./latest_push_sign_app.sh -t enterprise -p "$GENERIC_NIKE_PROFILE" -a "$i" -e ../Entitlements.xml || ../../../../ProvisioningProfiles/./latest_push_sign_app.sh -t enterprise -p "$GENERIC_NIKE_PROFILE" -a "$i" || callForFailure "Signing of the app failed"
    	ProvisioningProfile="$GENERIC_NIKE_PROFILE"
    	ProvisioningProfileName="Generic Nike Profile"
    else
        profilePath="Push notification signing with profile:  $PROFILE_DESTINATION/$APP_NAME.mobileprovision"
        echo "$profilePath"
        ../../../../ProvisioningProfiles/./latest_push_sign_app.sh -t enterprise -p $PROFILE_DESTINATION/$APP_NAME.mobileprovision -a "$i" -e ../Entitlements.xml || ../../../../ProvisioningProfiles/./latest_push_sign_app.sh -t enterprise -p "$GENERIC_NIKE_PROFILE" -a "$i" || callForFailure "Push Notification Signing failed"
    	ProvisioningProfile="$PROFILE_DESTINATION/$APP_NAME.mobileprovision"
    	ProvisioningProfileName="$APP_NAME Profile"
    fi
    codesign -v --no-strict "$i" || callForFailure "Failed to verify signing."
    #codesign -d -r "$i" || callForFailure "Failed to find the information of code signing."
done
echo "Profile: $ProvisioningProfile" 
ProfileExpirationDate=$(security cms -D -i "$ProvisioningProfile" | awk -F"[<>]" '/ExpirationDate/ {getline;print $3;exit}')
echo "Expiration date: $ProfileExpirationDate" 
ProfileExpirationDate=$(echo "$ProfileExpirationDate" | sed -e "s/ /%20/g")
echo "Expiration date: $ProfileExpirationDate" 
Result="App was signed with $ProvisioningProfileName, which expires on $ProfileExpirationDate."
Result=$(echo "$Result" | sed -e "s/ /%20/g")
CLIENT_URL="$CLIENT_URL$urlParameters&Result=$Result"
echo "$CLIENT_URL"
echo "$CLIENT_URL"
curl -s "$CLIENT_URL" || callForFailure "Updating the status to the server with a curl call"

printEmptyLines


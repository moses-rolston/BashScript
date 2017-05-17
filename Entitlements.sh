#!/bin/bash

JENKINS_WORK_SPACE="/Users/a.appsubmission/.jenkins/jobs/UnZipProcess/workspace"

SHARED_DISK_VOLUME="/Volumes/Projects/MobileApps/Production"

CURRENT_WORKSPACE="$SHARED_DISK_VOLUME"
CURRENT_PROJECT="$CURRENT_WORKSPACE/project"
CURRENT_PARAMETER_LOCATION="$CURRENT_PROJECT/parameters.txt"
CURRENT_ALT_PARAMETER_LOCATION="$CURRENT_WORKSPACE/parameters.txt"
CURRENT_PROJECTS="$CURRENT_WORKSPACE/Projects"

LabelValue="L52544R8JN"


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
projectType=""
isIPA=false
ipaExist=false
ipaFileName=""
isFolder=false
folderExist=false
isBundleID=false
counter=-1
reqType=""
version=""
appTitle=""
isUrl=false
urlParameters=""
isPushStar=false
isPush=false
isClientUrl=false
CLIENT_URL="http://mobileappstdev.nike.com:8090/ApplicationSubmission/Public/UpdateJobResult"

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
        reqType="$parameters"
    elif [ $counter -eq 1 ]; then
        counter=2
        version="$parameters"
    elif [ $counter -eq 2 ]; then
        counter=3
        appTitle="$parameters"
    else
        file="$parameters"
# isReturn=true
    fi
done < "$CURRENT_PARAMETER_LOCATION" || callForFailure "reading the parameters"

echo "CLIENT_URL: $CLIENT_URL"

function processLabel() {
    IFS="." read -a arrayString <<< "$1" || callForFailure "splitting the label based on dot inside processLabel"
    result="<string>$LabelValue"
    isCom=false
    isAfterNike=false
    isSequence=false
    isNike=false
    nikePosition=-1
    for (( i=1; i<"${#arrayString[@]}"; i++ ))
    do
        if [ "${arrayString[i]}" = "nike" ]; then
            isNike=true
            nikePosition=$i
        fi
        if [ "${arrayString[i]}" = "com" ]; then
            isCom=true
            result="$result.${arrayString[i]}" || callForFailure "processing the label"
        elif [ "$isCom" = true ]; then
            result="$result.nike" || callForFailure "processing the label"
            isCom=false
            isAfterNike=false
            isSequence=true
        elif [ "$isAfterNike" = true ]; then
            isAfterNike=false
            result="$result.RetailBrandiPhone" || callForFailure "processing the label"
        else
            result="$result.${arrayString[i]}" || callForFailure "processing the label"
        fi
    done
#If bundle is not in a  proper format such as not like "com.nike." but like "eg: "es.digiworks.nike.su14.mensathletic " it will process it to get the correct format
    if [ "$isSequence" = false ]; then
        result="<string>$LabelValue"
        isNikeReached=false
        if [ "$nikePosition" -gt -1 ]; then
            for (( i=1; i<"${#arrayString[@]}"; i++ ))
            do
                if [ "$nikePosition" -eq 1 ]; then
                    isNikeReached=true
                    result="$result.com.nike"
                elif [ "$nikePosition" -eq "$(( $i + 1 ))" ]; then
                    isNikeReached=true
                    result="$result.com"
                elif [ "$isNikeReached" = true ]; then
                    result="$result.${arrayString[i]}"
                fi
            done
        else
            result="$result.com.nike"
            for (( i=1; i<"${#arrayString[@]}"; i++ ))
            do
                result="$result.${arrayString[i]}"
            done
        fi
    fi
#    if [ "$result" = "<string>$LabelValue.com.nike.VRLink-Nike</string>" ]; then
#    	result="<string>$LabelValue.com.nike.wholesale.golf.VRLink</string>"
#    fi
    echo $result
}

function processVRLinkLabel() {
	if [ "$result" = "<string>$LabelValue.com.nike.VRLink-Nike</string>" ]; then
    	result="<string>$LabelValue.com.nike.wholesale.golf.VRLink</string>"
    fi
}
 
function processEntitlements() {
    echo " "
    echo ">>>>>>>>>>>>>>    Processing Entitlements...  <<<<<<<<<<<<<<<<"
    cd ../../ || callForFailure "changing the directory ../../"
    isSpecialChar=true
    isGetTaskAllowValue=false
    additionalLine=0
    dopListClosed=false
    isDeveloperTeamIdentifier=false
    isBetaReportActive=false
    isDeveloperAssociatedDomains=false
    isSecurityApplicationGroups=false
    dontWrite=false
    entitlementLineCounter=0
    isAPSAvailable=false
    while read p; do
        if [ "$isSpecialChar" = true ]; then
            echo "Special $p"
            isSpecialChar=false
        else
            if [ "$p" = "<key>get-task-allow</key>" ]; then
                isGetTaskAllowValue=true
            elif [ "$isGetTaskAllowValue" = true ]; then
                echo "Changed the get-task-allow value from true to false."
                p="<false/>"
                isGetTaskAllowValue=false
            elif [ "$p" = "<key>com.apple.developer.associated-domains</key>" ]; then
                isDeveloperAssociatedDomains=true
                dontWrite=true
            elif [ "$isDeveloperAssociatedDomains" = true ]; then
                isDeveloperAssociatedDomains=false
                dontWrite=true
            elif [ "$p" = "<key>com.apple.developer.team-identifier</key>" ]; then
                isDeveloperTeamIdentifier=true
                dontWrite=true
            elif [ "$isDeveloperTeamIdentifier" = true ]; then
                isDeveloperTeamIdentifier=false
                dontWrite=true
                #p="<string>$LabelValue</string>"
            elif [ "$p" = "<key>beta-reports-active</key>" ]; then
                isBetaReportActive=true
                dontWrite=true
            elif [ "$isBetaReportActive" = true ]; then
                isBetaReportActive=false
                dontWrite=true
            elif [ "$p" = "<key>com.apple.security.application-groups</key>" ]; then
                isSecurityApplicationGroups=true
                dontWrite=true
            elif [ "$isSecurityApplicationGroups" = true ]; then
                isSecurityApplicationGroups=false
                dontWrite=true
            elif [ "$p" = "<key>application-identifier</key>" ]; then
                isAppIdentifier=true
            elif [ "$isAppIdentifier" = true ]; then
                isAppIdentifier=false
                echo "Initial Application Identifier value: $p"
                p=$(processLabel "$p") || callForFailure "call for processLabel"
                finalBundleID="$p"
                echo "Final Bundle: $finalBundleID"
                finalBundleID=$(echo "$finalBundleID" | sed -e "s/<string>L52544R8JN.//g")
                finalBundleID=$(echo "$finalBundleID" | sed -e "s/<\/string>//g")
                echo "New Application Identifier value: $p-> $finalBundleID"
            elif [ "$p" = "<array>" ]; then
                isArray=true
            elif [ "$isArray" = true ]; then
                if [ "$p" = "</array>" ]; then
                    isArray=false
                else
                    if [ $additionalLine = 0 ]; then
                        echo "Initial Array value: $p"
                        p=$(processLabel "$p") || callForFailure "call for processLabel"
                        finalBundleID="$p"
                        echo "Final Bundle: $finalBundleID"
                        finalBundleID=$(echo "$finalBundleID" | sed -e "s/<string>L52544R8JN.//g")
                        finalBundleID=$(echo "$finalBundleID" | sed -e "s/<\/string>//g")
                        echo "New Array value: $p-> $finalBundleID"
                        additionalLine=1
                    else
                        additionalLine=2
                        p=""
                    fi
                fi
            elif [ "$p" = "<key>aps-environment</key>" ]; then
                isAPSAvailable=true
                if [ "$isPush" = false ]; then
                    callForFailure "Push Notification Enabled: $finalBundleID. Requires unique APNS profile and certificate."
                fi
            fi
            echo "$p"
            if [ "$additionalLine" = 2 ]; then
                additionalLine=0
            elif [ "$dontWrite" = true ]; then
                dontWrite=false
            else
                echo "$p" >> Entitlements.xml || callForFailure "writing to Entitlements.xml file"
            fi
            if [ "$additionalLine" = "</plist>" ]; then
                dopListClosed=true
            fi
        fi
        entitlementLineCounter=$entitlementLineCounter+1
    done < ./Entitlements1.xml || callForFailure "reading from Entitlements1.xml file"
    if [ "$dopListClosed" = false ] && [ "$p" == "</plist>" ]; then
    	echo "Value is $p"
        echo "</plist>" >> Entitlements.xml || callForFailure "writing to Entitlements.xml file"
    fi
    rm -rf Entitlements1.xml || callForFailure "removing the Entitlements1.xml file"
#Check Entitlements file is created properly
    if [ "$entitlementLineCounter" == 0 ]; then
        rm -rf Entitlements.xml || callForFailure "removing the Entitlements1.xml file"
        entitlementsFailed "$1"
    fi
}

function createEntitlements() {
    echo " "
    echo ">>>>>>>>>>>>>>    Processing Entitlements...  <<<<<<<<<<<<<<<<"
    cd ../../ || callForFailure "changing the directory ../../"
    cp ../Entitlements.xml ./Entitlements1.xml
    isSpecialChar=true
    isGetTaskAllowValue=false
    while read p; do
            if [ "$p" = "<key>application-identifier</key>" ]; then
                isAppIdentifier=true
            elif [ "$isAppIdentifier" = true ]; then
                isAppIdentifier=false
                echo "Initial Application Identifier value: $p"
                p="<string>$LabelValue.$finalBundleID</string>" || callForFailure "call for processLabel"
                echo "New Application Identifier value: $p"
            elif [ "$p" = "<array>" ]; then
                isArray=true
            elif [ "$isArray" = true ]; then
                isArray=false
                echo "Initial Array value: $p"
                p="<string>$LabelValue.$finalBundleID</string>" || callForFailure "call for processLabel"
                echo "New Array value: $p"
            fi
            echo "$p"
            echo "$p" >> Entitlements.xml || callForFailure "writing to Entitlements.xml file"
    done < ./Entitlements1.xml || callForFailure "reading from Entitlements1.xml file"
    rm -rf Entitlements1.xml || callForFailure "removing the Entitlements1.xml file"
}


function entitlementsExist() {
    j=$(echo "$1" | sed 's/ /\ /g')
    fileName=$(basename "$j") || callForFailure "Finding the base name"
    fileName=$(echo ${fileName// /_}) || callForFailure "Replacing spaces with _ character"
    fileName=$(echo $fileName | sed -e "s/.app//g") || callForFailure "finding the file name without extension"
    echo "$j file name is $fileName"
    echo $fileName >> "$CURRENT_PARAMETER_LOCATION"
    cd "$j" || callForFailure "changing the directory to $j"
    processEntitlements "$j" || callForFailure "call to the method processEntitlements"
}

function bundleIDCheck() {
    pListBundleID=$(/usr/libexec/PlistBuddy -c "print :CFBundleIdentifier" "$1") || callForFailure "Getting the bundle ID from Plist"
    IFS="." read -a arrayBundleID <<< "$pListBundleID" || callForFailure "Splitting the Bundle ID against ."
    if [ ${arrayBundleID[1]} != "nike" ]; then
        echo "Improper format of Bundle ID i.e. nike is missing: $pListBundleID"
        finalBundleID=${arrayBundleID[0]}".nike" || callForFailure "Getting the bundle ID from PList"
        for (( i=2; i<"${#arrayBundleID[@]}"; i++ ))
        do
            finalBundleID=$finalBundleID"."${arrayBundleID[$i]} || callForFailure "Changing the Bundle ID inside PList"
        done
        echo "Final edited bundle id is $finalBundleID"
        /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier '${finalBundleID}'" "$1" || callForFailure "Printing and seeting the bundle identifier from Plist"
    else
        finalBundleID="$pListBundleID"
        echo "Proper format of Bundle ID with nike: $pListBundleID"
    fi
}

function enterIntoAppToGetBundleID() {
    j=$(echo "$1" | sed 's/ /\ /g')
    fileName=$(basename "$j") || callForFailure "Finding the base name"
    fileName=$(echo ${fileName// /_}) || callForFailure "Replacing spaces with _ character"
    fileName=$(echo $fileName | sed -e "s/.app//g") || callForFailure "finding the file name without extension"
    echo "$j file name is $fileName"
    echo $fileName >> "$CURRENT_PARAMETER_LOCATION"
    cd "$j" || cd "./Payload/$j" || callForFailure "changing the directory to $j"
    for k in *.plist; do
        if [ "$k" = "Info.plist" ]; then
            bundleIDCheck "$k" || callForFailure "editPListFile method with parameter $k"
            break
        fi
    done
}



function entitlementsFailed() {
    echo "------------------No Entitlements------------------"
    j=$(echo "$1" | sed 's/ /\ /g')
    enterIntoAppToGetBundleID "$j"
    createEntitlements
}

function enterPayload() {
	pwd
	ls -l
    cd Payload || callForFailure "change directory to Payload"

    for j in *.app; do
        codesign -d --entitlements - "$j" >> ../Entitlements1.xml && entitlementsExist "$j" || entitlementsFailed "$j" || callForFailure "$1 . Running the command that shows the entitlements exists or not and also writing the output to Entitlements1.xml"
    done

}

function processIPAFile() {
    mv "${1}" "${1%.ipa}.zip" || callForFailure "converting the ipa file to zip file"
    for i in *.zip; do
        unzip "$i" >> results.txt || callForFailure "unzipping the converted zip file"
        rm -rf $i || callForFailure "removing the converted zip file"
        rm -rf __MACOSX || callForFailure "removing the unwanted __MACOSX folder"
        enterPayload
    done
}

function findIPAs() {
    echo ">>>>>>>>>>>>>>>>>>>>>>>>  Finding the ipa file...     <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    iPAFiles=$(find . -type f \( -name "*.ipa" \)|wc -l) || callForFailure "finding the number of .ipa files"
    if [ $iPAFiles -eq 0 ] ; then
        echo "******The IPA file is missing.*******"
        callForFailure "number of ipa files is zero"
    else
        echo "Number of IPA files found " $iPAFiles
        echo "Name of the IPA file is -->  $ipaFileName"
        processIPAFile "$ipaFileName" ||
        callForFailure "call to processIPAFile method"
    fi
}

printEmptyLines
if [ "$isReturn" = true ]; then
    enterPayload
else
    cd "$file"
    findIPAs || callForFailure "call to the method findIPAs method"
fi

echo "Final Bundle ID: $finalBundleID"
if [ "$finalBundleID" = "$BUNDLE_ID" ]; then
    Result="Entitlements are processed successfully. Bundle ID matched with old version: $BUNDLE_ID&AppBundleID=$finalBundleID"
    echo "Entitlements are processed successfully. Bundle ID matched with old version: $BUNDLE_ID&AppBundleID=$finalBundleID"
    Result=$(echo "$Result" | sed -e "s/ /%20/g")
	CLIENT_URL="$CLIENT_URL$urlParameters&Result=$Result"
	echo $CLIENT_URL
	curl -s "$CLIENT_URL" || callForFailure "Updating the status to the server with a curl call"
	printEmptyLines
elif [ "$BUNDLE_ID" = "New App" ]; then
    Result="Entitlements are processed successfully. New App request: $BUNDLE_ID&AppBundleID=$finalBundleID"
    echo "Entitlements are processed successfully. New App request: $BUNDLE_ID&AppBundleID=$finalBundleID"
    Result=$(echo "$Result" | sed -e "s/ /%20/g")
	CLIENT_URL="$CLIENT_URL$urlParameters&Result=$Result"
	echo $CLIENT_URL
	curl -s "$CLIENT_URL" || callForFailure "Updating the status to the server with a curl call"
	printEmptyLines
else
    callForFailure "Entitlements process failed. Bundle ID cannot be changed. App Bundle ID: $finalBundleID != Stored Bundle ID: $BUNDLE_ID"
    echo "Entitlements process failed. Bundle ID: $finalBundleID != $BUNDLE_ID"
fi


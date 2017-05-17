#!/bin/bash

JENKINS_WORK_SPACE="/Users/a.appsubmission/.jenkins/jobs/UnZipProcess/workspace"

SHARED_DISK_VOLUME="/Volumes/Projects/MobileApps/Production"

CURRENT_WORKSPACE="$SHARED_DISK_VOLUME"
CURRENT_PROJECT="$CURRENT_WORKSPACE/project"
CURRENT_PARAMETER_LOCATION="$CURRENT_PROJECT/parameters.txt"
CURRENT_ALT_PARAMETER_LOCATION="$CURRENT_WORKSPACE/parameters.txt"
CURRENT_PROJECTS="$CURRENT_WORKSPACE/Projects"

sampleManifestLoc="$CURRENT_WORKSPACE/sample_manifest.plist"
appBasicURL="http://mobileapps.nike.com:8090/"

function printEmptyLines() {
    echo " "
    echo " "
    echo " "
}

printEmptyLines
echo "Build Number $1"
function callForFailure() {
    Result="Failed to execute the command at $1"
    echo "$Result"
    Result=$(echo "$Result" | sed -e "s/ /%20/g")
    CLIENT_URL="$CLIENT_URL$urlParameters&Result=$Result"
    curl -s "$CLIENT_URL"
    echo " !!!!!!!!!!!!!!! Failure !!!!!!!!!!!!!!!!!!!!!" && printEmptyLines && cd error
    exit
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
bundleVersionValue=""
bundleIDValue=""
bundleNameValue=""
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
        appRequest="$parameters"
    elif [ $counter -eq 1 ]; then
        counter=2
        version="$parameters"
    elif [ $counter -eq 2 ]; then
        counter=3
        appName="$parameters"
        appName=$(echo ${appName// /_})
        destFolderName=$appName
    elif [ $counter -eq 3 ]; then
        counter=4
        projectName="$parameters"
        projectName=$(echo ${projectName// /_}) || callForFailure "processing the projectName parameters"
    elif [ $counter -eq 4 ]; then
        counter=5
        bundleVersionValue="$parameters"
    elif [ $counter -eq 5 ]; then
        counter=6
        bundleIDValue="$parameters"
    elif [ $counter -eq 6 ]; then
        counter=7
        bundleNameValue="$parameters"
    else
        file="$parameters"
        isReturn=true
    fi
done < "$CURRENT_ALT_PARAMETER_LOCATION" || callForFailure "reading the parameters"

echo "CLIENT_URL: $CLIENT_URL"
cd $destFolderName/New/Payload || callForFailure "Changing the directory at lin 41"

function createManifest() {
    cat >> manifest.plist || callForFailure "creation of manifest file"
    chmod 777 manifest.plist || echo "Changing permissions of manifest.plist file"
    while read parameters; do
        if [ "$parameters" = "<string>IPA_URL</string>" ]; then
            finalParameters="<string>"$appBasicURL"Projects/"$destFolderName"/New/${fileName%.zip}.ipa</string>"
        elif [ "$parameters" = "<string>512_URL</string>" ]; then
            finalParameters="<string>http://mobileapps.nike.com:8090/Images/Nike_Golf/512.png</string>"
        elif [ "$parameters" = "<string>57_URL</string>" ]; then
            finalParameters="<string>http://mobileapps.nike.com:8090/Images/Nike_Golf/icon.png</string>"
        elif [ "$parameters" = "<string>BUNDLE_ID_VALUE</string>" ]; then
            finalParameters="<string>"$bundleIDValue"</string>"
        elif [ "$parameters" = "<string>BUNDLE_VERSION_VALUE</string>" ]; then
            finalParameters="<string>"$bundleVersionValue"</string>"
        elif [ "$parameters" = "<string>SUB_TITLE_VALUE</string>" ]; then
            finalParameters="<string>"$appName"</string>"
        elif [ "$parameters" = "<string>TITLE_VALUE</string>" ]; then
            finalParameters="<string>"$bundleNameValue"</string>"
        else
            finalParameters=$parameters
        fi
        echo "$finalParameters" >> manifest.plist || callForFailure "writing to manifest.plist file"
    done < $sampleManifestLoc || callForFailure "reading the sampleManifest file"
}

plist="</plist>"




for i in *.app; do
    echo $i
    fileName=$(basename "$i") || callForFailure "Finding the base name"
    fileName=$(echo ${fileName// /_}) || callForFailure "Replacing spaces with _ character"
    fileName=$(echo $fileName | sed -e "s/.app//g") || callForFailure "finding the file name without extension"
    fileName=$fileName"_signedIPA.zip" || callForFailure "creating the custom name with zip extension"
done




cd ..
zip -r $fileName Payload > results.txt || callForFailure "converting the zip file to ipa file"
rm -rf Payload
chmod 777 $fileName || echo "failed to change permissions of $fileName."

mv "${fileName}" "${fileName%.zip}.ipa" || callForFailure "converting the extension zip file to ipa"

createManifest
appInstallUrl="itms-services://?action=download-manifest&url="$appBasicURL"Projects/"$destFolderName"/New/manifest.plist"

echo "Successful Creation of ipa file i.e, ${fileName%.zip}.ipa is done for the request of $appRequest."
newArtifact="http://mobileapps.nike.com:9494/view/Signing%20Process/job/Create%20Signed%20IPA/^/artifact/"$destFolderName"/New/"${fileName%.zip}.ipa
echo "New artifact is $newArtifact"
oldArtifact="http://mobileapps.nike.com:9494/view/Signing%20Process/job/Create%20Signed%20IPA/^/artifact/"$destFolderName"/Old/"${fileName%.zip}.ipa
echo "Old artifact is $oldArtifact"
directNewProjectURL="https://mobileapps.nike.com:8443/Projects/"$destFolderName"/New/"${fileName%.zip}.ipa
directOldProjectURL="https://mobileapps.nike.com:8443/Projects/"$destFolderName"/Old/"${fileName%.zip}.ipa
Result="Creation of final signed ${fileName%.zip}.ipa file is Successful."
Result=$(echo "$Result" | sed -e "s/ /%20/g")
CLIENT_URL="$CLIENT_URL$urlParameters&Result=$Result&BuildNumber=$1&PreviousBuildPath=$directOldProjectURL&CurrentBuildPath=$directNewProjectURL&AppInstallUrl=$appInstallUrl"
echo "$CLIENT_URL"
curl -s "$CLIENT_URL" || callForFailure "Updating the status to the server with a curl call"
printEmptyLines


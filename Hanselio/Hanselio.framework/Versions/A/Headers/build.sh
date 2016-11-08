#!/bin/sh

#  post_build.sh
#  PebbletraceDevelopmentTest
#
#  Created by Prabodh Prakash on 27/06/16.
#  Copyright © 2016 Hansel. All rights reserved.

fileName="config.json"
forwardSlash="/"
hanselDirectory="Hansel"
preprocessorVersion=0.0.1

ARCHIVE_BASE="${HOME}/Desktop/${hanselDirectory}/"
FILE_NAME="crumb.dSYM"

function traverseAndCopy
{
    for file in "$1"/*;
    do
        if [ -d "${file}" ] ; then
            if [ ${file: -5} == ".dSYM" ] ; then
                cp -Rp ${file} ${ARCHIVE_BASE}${FILE_NAME}
            else
                traverseAndCopy "${file}"
            fi
        fi
    done
}

function createDirectory
{
    [ ! -d $ARCHIVE_BASE ] && mkdir -p `expand $ARCHIVE_BASE`
}

function expand
{
    echo `sh -c "echo $1"`
}

function createFile
{
    [ ! -e $ARCHIVE_BASE$fileName ] && echo $(createJSON) > $ARCHIVE_BASE$fileName
}

function getBuildNumber
{
    local buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PROJECT_DIR}/${INFOPLIST_FILE}")
    echo "$buildNumber"
}

function getVersionNumber
{
    local versionNumber=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${PROJECT_DIR}/${INFOPLIST_FILE}")
    echo "$versionNumber"
}

function getPreProcessorVersion
{
    echo "$preprocessorVersion"
}

function getBundleIdentifier
{
    cfBundleIdentifier=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "${PROJECT_DIR}/${INFOPLIST_FILE}")
    echo `eval echo $cfBundleIdentifier`
}

function getExpandedBundleIdentifier
{
    bundleIdentifier=$(getBundleIdentifier)
    cfBundleIdentifier=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "${PROJECT_DIR}/${INFOPLIST_FILE}")
    variableArray=($(echo $cfBundleIdentifier | awk -F'[$()]'  '{j=0; for(i=0;i<=NF;i+=1){print $i;}}'))
    for i in "${variableArray[@]}"
    do
        if [[ $i == "PRODUCT_NAME:rfc1034identifier" ]]; then
            i="PRODUCT_NAME"
        fi
        bundleIdentifier=$bundleIdentifier${!i}
    done

    echo $bundleIdentifier
}

function getHanselSDKVersion
{
    local hanselSDKVersion=$(/usr/libexec/PlistBuddy -c "Print :sdk_version" "${SRCROOT}/Pods/Hansel.io-ios/Hanselio/Hanselio.framework/Headers/PebbletraceInfo.plist")
                     
    echo "$hanselSDKVersion"
}
                     
function getiosMinSDKVersion
{
    local iosMinSDKVersion=$(/usr/libexec/PlistBuddy -c "Print :ios_min_sdk_version" "${SRCROOT}/Pods/Hansel.io-ios/Hanselio/Hanselio.framework/Headers/PebbletraceInfo.plist")
                     
    echo "$iosMinSDKVersion"
}

function getiosTargetSDKVersion
{
    local iosTargetSDKVersion=$(/usr/libexec/PlistBuddy -c "Print :ios_target_sdk_version" "${SRCROOT}/Pods/Hansel.io-ios/Hanselio/Hanselio.framework/Headers/PebbletraceInfo.plist")
    
    echo "$iosTargetSDKVersion"
}

function createJSON
{
    local buildNumber=$(getBuildNumber)
    local appVersion=$(getVersionNumber)
    local preProcessorVersion=$(getPreProcessorVersion)
    local bundleIdentifier=$(getExpandedBundleIdentifier)
    local hanselSDKVersion=$(getHanselSDKVersion)
    local iosMinSDKVersion=$(getiosMinSDKVersion)
    local iosTargetSDKVersion=$(getiosTargetSDKVersion)
    
    echo "{\"preprocessor_version\":\"$preProcessorVersion\",\"app_version\":\"$appVersion\",\"app_version_code\":\"$buildNumber\",\"bundle_identifier\":\"$bundleIdentifier\",\"sdk_version\":\"$hanselSDKVersion\",\"settings\":{\"is_proguard_available\":false},\"ios_min_sdk_version\" : $iosMinSDKVersion,\"ios_target_sdk_version\" : $iosTargetSDKVersion}"
}

function createFunctionList
{
    python ${SRCROOT}/Pods/Hansel.io-ios/Hanselio/Hanselio.framework/Headers/dsymparser.py
}

function createZip
{
    pushd $ARCHIVE_BASE
    rm -rf "crumb.dSYM"
    zip -r "Hansel.zip" .
    popd $ARCHIVE_BASE
}

function clean
{
    pushd $ARCHIVE_BASE
    [ -e "crumb.dSYM" ] && rm "crumb.dSYM"
    [ -e "config.json" ] && rm "config.json"
    [ -e "function-list" ] && rm "function-list"
}

createDirectory
createFile
echo ${DWARF_DSYM_FOLDER_PATH}
traverseAndCopy "${DWARF_DSYM_FOLDER_PATH}"
createFunctionList
createZip
clean

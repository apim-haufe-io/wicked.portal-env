#!/bin/bash

# Use this file after you have made changes to portal-env which you need
# to propagate into the different packages. This is done by the build scripts
# automatically via portal-env being the base for all other docker images, but
# if you need to update locally, try this.

echo "==== STARTING ==== $0"

trap failure ERR

function failure {
    echo "=================="
    echo "====  ERROR   ==== $0"
    echo "=================="
}

set -e

# Check whether jq is installed (should be)
if ! which jq > /dev/null; then
    echo "ERROR: This script requires 'jq' to be installed."
    exit 1
fi

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd ${currentDir} > /dev/null

envVersion=$(cat package.json | jq '.version' | tr -d '"')
if [[ -z "${envVersion}" ]]; then
    echo "ERROR: Could not retrieve portal-env version from package.json"
    exit 1
fi

echo "INFO: Updating portal-env in repositories which needs it."
echo "INFO: portal-env v${envVersion}"

packageFile="portal-env-${envVersion}.tgz"
logFile="wicked.portal-env/local-update-portal-env.log"
rm -f portal-env-*
rm -f ../${packageFile}

npm pack > /dev/null
echo "INFO: Package file: ${packageFile}"
mv ${packageFile} ..

if [ "$1" = "--copy" ]; then
    echo "INFO: Only copied package file; npm install has to be run later."
else
    for prefix in "" "wicked."; do
        for wickedDir in \
            "portal-api" \
            "portal" \
            "portal-auth" \
            "portal-kong-adapter" \
            "portal-mailer" \
            "portal-chatbot" \
            "portal-kickstarter"; do

            if [ -d "../${prefix}${wickedDir}" ]; then 
                echo "INFO: Updating ${prefix}${wickedDir}"
                pushd ../${prefix}${wickedDir} > /dev/null
                npm install ../${packageFile} >> ../${logFile}
                popd > /dev/null 
            fi
        done
    done

    for wickedDir in \
        "wicked.portal-test/portal-api"; do

        if [ -d "../${wickedDir}" ]; then 
            echo "INFO: Updating ${wickedDir}"
            pushd ../${wickedDir} > /dev/null
            npm install ../../${packageFile} >> ../../${logFile}
            popd > /dev/null 
        fi
    done
fi

popd > /dev/null # currentDir

echo "==== SUCCESS ==== $0"

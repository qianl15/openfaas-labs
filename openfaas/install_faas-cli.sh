#!/bin/bash

# This script is originally from https://cli.openfaas.com
# It will help you to install the faas-cli version 0.6.9

version=$(curl -s https://api.github.com/repos/openfaas/faas-cli/releases/tags/0.6.9 | grep 'tag_name' | cut -d\" -f4)
if [ ! $version ]; then
    echo "Failed while attempting to install faas-cli. Please manually install:"
    echo ""
    echo "1. Open your web browser and go to https://github.com/openfaas/faas-cli/releases"
    echo "2. Download the latest release for your platform. Call it 'faas-cli'."
    echo "3. chmod +x ./faas-cli"
    echo "4. mv ./faas-cli /usr/local/bin"
    echo "5. ln -sf /usr/local/bin/faas-cli /usr/local/bin/faas"
    exit 1
fi

echo "Installing faas-cli version 0.6.9"

hasCli() {
 
    has=$(which faas-cli)

    if [ "$?" = "0" ]; then
        echo
        echo "You already have the faas-cli!"
        export n=1
        echo "Overwriting in $n seconds.. Press Control+C to cancel."
        echo
        sleep $n
    fi

    hasCurl=$(which curl)
    if [ "$?" = "1" ]; then
        echo "You need curl to use this script."
        exit 1
    fi
}


getPackage() {
    uname=$(uname)
    userid=$(id -u)

    suffix=""
    case $uname in
    "Darwin")
    suffix="-darwin"
    ;;
    "Linux")
        arch=$(uname -m)
        echo $arch
        case $arch in
        "aarch64")
        suffix="-arm64"
        ;;
        esac
        case $arch in
        "armv6l" | "armv7l")
        suffix="-armhf"
        ;;
        esac
    ;;
    esac

    targetFile="/tmp/faas-cli"
    
    if [ "$userid" != "0" ]; then
        targetFile="$(pwd)/faas-cli"
    fi

    if [ -e $targetFile ]; then
        rm $targetFile
    fi

    url=https://github.com/openfaas/faas-cli/releases/download/$version/faas-cli$suffix
    echo "Downloading package $url as $targetFile"

    curl -sSL $url > $targetFile

    if [ "$?" = "0" ]; then

    chmod +x $targetFile

    echo "Download complete."
       
        if [ "$userid" != "0" ]; then
            
            echo
            echo "=========================================================" 
            echo "==    As the script was run as a non-root user the     =="
            echo "==    following commands may need to be run manually   =="
            echo "========================================================="
            echo
            echo "  sudo cp faas-cli /usr/local/bin/"
            echo "  sudo ln -sf /usr/local/bin/faas-cli /usr/local/bin/faas"
            echo

        else

            echo
            echo "Running as root - Attemping to move faas-cli to /usr/local/bin"

            mv $targetFile /usr/local/bin/
        
            if [ "$?" = "0" ]; then
                echo "New version of faas-cli installed to /usr/local/bin"
            fi

            if [ -e $targetFile ]; then
                rm $targetFile
            fi

            if [ ! -L /usr/local/bin/faas ]; then
            ln -s /usr/local/bin/faas-cli /usr/local/bin/faas
            echo "Creating alias 'faas' for 'faas-cli'."
        fi
        fi
    fi
}

hasCli
getPackage

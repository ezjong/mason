#!/usr/bin/env bash

# platform check
platform="$(uname)"
case $platform in
   'Linux')
        ubuntu_version="$(lsb_release -r | awk '{print $2}')"
        case $ubuntu_version in
            "16.04")
                #allgood
                ;;
            *)
                echo "Ubuntu $ubuntu_version not supported!"
                exit 1
                ;;
        esac
        ;;
   '*')
        echo "Platform $platform not supported!"
        return 1
        ;;
esac

# read environment name
default_name='anaconda2'
echo -n "Choose environment name [default: $default_name]: "
read env_name
if [ -z "$env_name" ]; then
    env_name=$default_name
fi

# install environment + anaconda2 + tensorflow
mason create $env_name
mason install $env_name anaconda2
mason install $env_name tensorflow-1.0-cp27-cuda8
mason install $env_name cuda-8.0-local
mason install $env_name cudnn-5.1.5-local

# say hello
clear; mason_welcome $env_name

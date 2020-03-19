#!/bin/bash

if [ -z $PROJECT_ID ]; then
    echo -e "\e[24mPROJECT_ID environment variable not set, exiting\e[0m"
    exit 1
fi

if [ -z $REPO_NAME ]; then
    echo -e "\e[24mREPO_NAME environment variable not set, exiting\e[0m"
    exit 1
fi

if [ -z $BUILD_ID ]; then
    echo -e "\e[24mBUILD_ID environment variable not set, exiting\e[0m"
    exit 1
fi



docker build -t asia.gcr.io/$PROJECT_ID/$REPO_NAME:$BUILD_ID \
             -t asia.gcr.io/$PROJECT_ID/$REPO_NAME:latest \
             --cache-from asia.gcr.io/$PROJECT_ID/$REPO_NAME:latest \
              .
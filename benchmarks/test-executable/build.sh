#!/bin/bash

gcc hello.c -o hello --static

DEPLOYDIR=deploy-pkg
mkdir -p $DEPLOYDIR
mv hello $DEPLOYDIR/

zip -jr exe-test.zip $DEPLOYDIR

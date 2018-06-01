#!/bin/bash

gcc hello.c -o hello --static

DEPLOYDIR=deploy-pkg
mkdir -p $DEPLOYDIR/bins/
mv hello $DEPLOYDIR/bins/

zip -r exe-test.zip $DEPLOYDIR/*

#!/bin/bash

HUB="faromero"

pushd tflow-env

sudo docker build --tag=${HUB}/tflow-env . && sudo docker push ${HUB}/tflow-env

popd

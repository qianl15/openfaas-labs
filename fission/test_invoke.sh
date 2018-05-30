#!/bin/bash

MAX_ITER=100
for i in `seq 1 ${MAX_ITER}`; do
curl -w "%{time_total}\n" http://${FISSION_ROUTER}/hello4 && echo "done ${i}" &
done
wait

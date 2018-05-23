#!/bin/bash

#curl -w "%{time_total}\n" http://35.227.191.202:31112/async-function/hello-openfaas --data-binary a && echo "done1" &
#wait

MAX_ITER=20
for i in `seq 1 ${MAX_ITER}`; do
echo -n "" | faas-cli invoke long-task --gateway=http://35.227.191.202:31112 --async
echo "done ${i}"
done
wait

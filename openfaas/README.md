# openfaas-workshop

This directory contains code for
[openfaas-workshop](https://github.com/openfaas/workshop)

## Install OpenFaaS on the server
Put our submodule `faas-netes` onto your kubernetes master machine.

```
cd faas-netes && \
    kubectl apply -f ./namespaces.yml,./yaml
```

Then you can verify that OpenFaaS has been installed by:
```
kubectl get all --namespace=openfaas
```

## Pull the templates
Follow the instructions:
```
faas-cli template pull
faas-cli new --list
```

Alternatively, we dumped the templates as a submodule. You can do:
```
cp -r templates/template .
```
Copy template to the current directory.

## Hello world in Python
First, create openfaas-hello basic template files:
```
faas-cli new --lang python3 hello-openfaas --prefix="<your-docker-username-here>"
```

The first step will create function in folder: `hello-openfaas`, stack file written
in `hello-openfaas.yml`. You need to modify `hello-openfaas/hanlder.py` to return
"Hello OpenFaaS" string.

Second, push docker image and deploy: (with this directory you can start from here)
```
faas-cli build -f ./hello-openfaas.yml
faas-cli push -f ./hello-openfaas.yml
faas-cli deploy -f ./hello-openfaas.yml --gateway http://<remote-ip>:31112
```

Finally, invoke the function
```
faas-cli invoke hello-openfaas -g http://<remote-ip>:31112
```

You should be able to get the result "Hello OpenFaaS" printed to stdout.
Note that I am using kubernetes as backend, so the gateway port is 31112.

## astronaut-finder
Similarly, the second example function is astronaut finder that pulls in a
random name of someone in space aboard the International Space Station (ISS).

Note that this time we modify `./astronaut-finder/requirements.txt` to add
a module named `requests`.
This tells the function it needs to use a third-party module named requests for
accessing websites over HTTP.

We also need to modify `./astronaut-finder/handler.py` to return the string.

Then the following step would be the same:
```
faas-cli build -f ./astronaut-finder.yml
faas-cli push -f ./astronaut-finder.yml
faas-cli deploy -f ./hello-openfaas.yml --gateway http://<remote-ip>:31112

faas-cli invoke astronaut-finder -g http://<remote-ip>:31112
```

## Custom binaries as functions
Follow the instructions [here](https://github.com/openfaas/workshop/blob/master/lab3.md#custom-binaries-as-functions-optional).
We can put `--lang=dockerfile` and deploy our customized binaries/containers.

I have the `sorter` and `long-task` examples for this custom binaries.

## Auto-scaling feature

To control scaling behaviour you can set a min/max scale value with a label
when deploying your function via the CLI or the API:
```
  labels:
    "com.openfaas.scale.min": "10"
    "com.openfaas.scale.max": "20"
```
I added this labels stuff at `long-task.yml` as an example.

## Get Function Logs
If you want to get the runtime logs about the function. Log in your kubernetes
master node and type:
```
kubectl logs <function-pod-name> --namespace=openfaas-fn
```

The pod name can be found by:
```
kubectl get pod --namespace=openfaas-fn
```

As described in the [workshop lab3](https://github.com/openfaas/workshop/blob/master/lab3.md#troubleshooting-verbose-output-with-write_debug), we can add `write_debug: true` to the YAML file and
re-deploy the function. Then we will be able to see detailed logs.

## Abnormal behavior
We found that OpenFaaS will simply fork multiple processes in the same container
if we only have 1 replica and invoke concurrently.
```
curl -w "%{time_total}\n" http://<remote-ip>/function/hello-openfaas && echo "done1" &
curl -w "%{time_total}\n" http://<remote-ip>/function/hello-openfaas && echo "done2" &
curl -w "%{time_total}\n" http://<remote-ip>/function/hello-openfaas && echo "done3" &

wait
```

On the kubernetes server side
```
 00:32:34 Forking fprocess.
 00:32:34 Forking fprocess.
 00:32:34 Forking fprocess.
 00:32:35 Wrote 15 Bytes - Duration: 0.217789 seconds
 00:32:35 Wrote 15 Bytes - Duration: 0.219228 seconds
 00:32:35 Wrote 15 Bytes - Duration: 0.214042 seconds
```
It seems that 3 processes have been created simultaneously, inside the same
container. This behavior is not the same as AWS Lambda, where each invocation
will start a new container. We might want to make the `watchdog` component of
OpenFaaS to be fully serialized.


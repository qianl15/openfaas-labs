# openfaas-workshop

This directory contains code for
[openfaas-workshop](https://github.com/openfaas/workshop)

## Pull the templates
Follow the instructions:
```
faas-cli template pull
faas-cli new --list
```

## Hello world in Python
First, create openfaas-hello basic template files:
```
faas-cli new --lang python3 hello-openfaas --prefix="<your-docker-username-here>" \
    --gateway=http://<remote-ip>:31112
```

The first step will create function in folder: `hello-openfaas`, stack file written
in `hello-openfaas.yml`. You need to modify `hello-openfaas/hanlder.py` to return
"Hello OpenFaaS" string.

Second, push docker image and deploy: (with this directory you can start from here)
```
faas-cli build -f ./hello-openfaas.yml
faas-cli push -f ./hello-openfaas.yml
faas-cli deploy -f ./hello-openfaas.yml
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
faas-cli deploy -f ./astronaut-finder.yml

faas-cli invoke astronaut-finder -g http://<remote-ip>:31112
```

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

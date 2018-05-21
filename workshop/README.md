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
in `hello-openfaas.yml`

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

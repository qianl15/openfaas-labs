# Fission

## Preparation

### Installation Guide
The original documentation is [here](https://docs.fission.io/0.7.2/installation/installation/).
You first need to set up a running kubernetes cluster. Fission requires at least
Kubernetes 1.6.

If you want a quick start, then download my [config](https://github.com/qianl15/config) repo.
And run:
```bash
cd config/gce
./install_k8s.sh
```

#### Helm
Install helm
```bash
curl -LO https://storage.googleapis.com/kubernetes-helm/helm-v2.7.0-linux-amd64.tar.gz
tar xzf helm-v2.7.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin
```

To avoid RBAC related issue, we need to install helm using a dedicated service
accaount:
```bash
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller --upgrade
```

#### Install Fission

##### Use Fission public release
It is pretty simple to use their release packet:
```bash
helm install --namespace fission https://github.com/fission/fission/releases/download/0.7.2/fission-all-0.7.2.tgz
```
The fission namespace in Kubernetes is `fission`, and the functions namespace is `fission-function`.

##### Build from scratch
If you changed some files inside fission and wanted to re-compile and install fission,
you can follow the instructions [here](https://docs.fission.io/0.7.2/installation/installation/).
But that instruction is not 100% correct. Here are my experiences:  
1. Install `go` (I installed go version 1.10)  
2. Install `glide`  
    ```bash
    sudo add-apt-repository ppa:masterminds/glide && sudo apt-get update
    sudo apt-get install glide
    ```  
3. Clone fission to your `$GOPATH/src/github.com/fission/fission`
    You can put our submodule `fission` to that directory.  
    ```bash
    cd $GOPATH/src/github.com/fission/fission
    glide install -v
    ```  
4. Build fission server and an image. Change the docker hub account to your
    own account, don't push to `fission` account. And remember to pass the
    version tag, otherwise, pods cannot find correct images. You may also need to
    log in to your docker account using `docker login` if you get the following error:
    *denied: requested access to the resource is denied*
    ```bash
    pushd fission-bundle
    sudo ./push.sh 0.7.2
    ```  
5. Finally, use helm to install fission. Run command from top fission directory.  
    ```bash
    helm install --set "image=<docker hub name>/fission-bundle,pullPolicy=IfNotPresent,analytics=false" charts/fission-all --namespace fission
    ```  
6. If you want to update CLI too, build with (from top fission directory):  
    ```bash
    cd fission && go install
    ```
    In addition, we provide an installation [script](https://github.com/qianl15/fission-s/blob/qianDev/fission/install-cli.sh).
    You can use that to compile with version, date, git commit data.

#### Install Fission CLI
On a remote/master machine, you can install the CLI by using their release download.
```bash
curl -Lo fission https://github.com/fission/fission/releases/download/0.7.2/fission-cli-linux && chmod +x fission && sudo mv fission /usr/local/bin/
```

#### Working remotely
By default, fission CLI only works for local deployment. Howerver, you can specify
the `--server` option in CLI commands to be the remote controller URL.
In order to use Fission from a remote client, you need to expose the controller
to a public TCP port!

On your kubernetes master node:
```bash
kubectl expose service controller --type=LoadBalancer --name=controller-open --namespace=fission --target-port=8888
```

Then check the public port for `controller-open` service:
```bash
kubectl get services --namespace=fission
```
> controller-open   LoadBalancer   ...   31112:<controller-port>/TCP  
> router            LoadBalancer   ...   80:<router-port>/TCP


On the remote client, set environmental variable:
```bash
export FISSION_URL=<remote-ip>:<controller-port>
export FISSION_ROUTER=<remote-ip>:<router-port>
```

Or you can pass `--server` option manually for each command:
```bash
fission --server=<remote-ip>:<controller-prot> ...
```

## Hello World Node.js example

This example derived from the [original site](https://docs.fission.io/0.7.2/usage/functions/).
1. You need to create an environment for that language (node.js here).
    On your server, or on your configured remote client.
    We are going to create an environment named `node`.
    ```bash
    fission env create --name node --image fission/node-env:0.4.0 \
        --mincpu 40 --maxcpu 80 --minmemory 64 --maxmemory 128 --poolsize 4 
    ```
    Then you can view environment information:
    ```bash
    fission env list
    ```
    This same environment can support many functions!

2. Then you can create your own function, we use [hello.js](hello.js) as an example.
    Let’s create a route for the function which can be used for making HTTP requests:
    ```bash
    fission route create --function hello --url /hello
    ```

    Then create a function based on pool based executor.
    ```bash
    fission fn create --name hello --code hello.js --env node --executortype poolmgr
    ```

3. Test the function by hitting its URL:
    ```bash
    curl http://$FISSION_ROUTER/hello
    ```

4. Similarly you can create a new deployment executor type function and provide minmum and maximum scale for the function.
    ```bash
    fission fn create --name hello --code hello.js --env node --minscale 1 --maxscale 5  --executortype newdeploy
    ```

5. If you need to update a function:
    ```bash
    fission fn update --name hello --code ../hello.js
    ```

## Fission Auto Scaling

In order to make HPA work, you need to start metrics server:
```bash
git clone https://github.com/kubernetes-incubator/metrics-server.git
cd metrics-server
kubectl create -f deploy/1.8+/
```

Then create a new function called `hello2`.
```bash
fission route create --function hello --url /hello2

fission fn create --name hello2 --env node --code hello.js --minmemory 64 --maxmemory 128 --minscale 1 --maxscale 6 --executortype newdeploy --targetcpu 50
```

Use `hey` to generate load. Note that hey only works for go version 1.7+
```bash
hey -c 250 -n 10000 http://$FISSION_ROUTER/hello2
```

Then watch the scaling effect by:
```bash
kubectl get hpa -n fission-function -w
```

## Fissioin builds/compiled functions
Fission allows us to deploy more complicated function packets.

Be aware that the storagesvc pod may not work correctly, refer to the 
[issue #618](https://github.com/fission/fission/issues/618).
My workaround was to edit volumes manually:
```bash
kubectl -n fission edit deploy storagesvc
```

and edit `volumes` section as follows:
```
volumes:
  - name: fission-storage
    emptyDir: {}
```

### From source
Based on original [post](https://docs.fission.io/0.7.2/usage/functions/#building-function-from-source),
The source code is at [sourcepkg](sourcepkg).

1. Create an environment with env image and python-builder image.
    ```bash
    fission env create --name python --image fission/python-env --builder fission/python-builder:latest --mincpu 40 --maxcpu 80 --minmemory 64 --maxmemory 128 --poolsize 2
    ```

2. Then zip the directory and create the function & route
    ```bash
    zip -jr demo-src-pkg.zip sourcepkg/
    fission fn create --name hellopy --env python --src demo-src-pkg.zip  --entrypoint "user.main" --buildcmd "./build.sh"
    fission route create --function hellopy --url /hellopy
    ```

3. You can check logs of the builder in `fission-builder` namespace:
    ```bash
    kubectl -n fission-builder logs -f <pod id> builder
    ```
    After the build process is succeeded, we can use that function as normal.

### From compiled package
Similar to AWS Lambda, we can deploy a pre-built deployment package to Fission.
The [documentation](https://docs.fission.io/0.7.2/usage/functions/#using-compiled-artifacts-with-fission)
has instructions to do that.

1. Create an environment with env image and python-builder image.
    ```bash
    fission env create --name python --image fission/python-env --builder fission/python-builder:latest --mincpu 40 --maxcpu 80 --minmemory 64 --maxmemory 128 --poolsize 2
    ```

2. Then zip the directory and create the function & route
    ```bash
    zip -jr demo-deploy-pkg.zip testDir/
    fission fn create --name hellopy --env python --deploy demo-deploy-pkg.zip --entrypoint "hello.main"
    fission route create --function hellopy --url /hellopy
    ```

3. Then we can test that function as usual.
    ```bash
    fission fn test --name hellopy
    ```

4. Or view the logs of that function (must on the server machine).
    ```bash
    fission fn logs --name hellopy
    ```

For more information about packaging source code, please refer to Fission official
[webpage](https://docs.fission.io/0.7.2/usage/package/).


## Invoke with Data & Python code

We can pass data into a python handler, the example file is [requestdata.py](requestdata.py).
For more python examples, please refer to [fission/examples/python](https://github.com/fission/fission/tree/master/examples/python).

`requestdata.py`:
```python
import sys
from flask import request
from flask import current_app

# Python env doesn't pass in an argument
# we can get request data by request.headers, request.get_data()
def main():
    current_app.logger.info("Received request")
    msg = '---HEADERS---\n{}\n--BODY--\n{}\n-----\n'.format(request.headers, request.get_data())
    current_app.logger.info(msg)

    # You can return any http status code you like, simply place a comma after
    # your return statement, and typing in the status code.
    return msg, 200
```

*Note that Python environment must specify `--entrypoint`.*

To test this script, simply create a function:
```bash
fission fn create --name reqdatapy --code requestdata.py --env python --executortype poolmgr --entrypoint "requestdata.main"
```

Or deploy with `newdeploy` type.
```bash
fission fn create --name reqdatapy --code requestdata.py --env python --entrypoint "requestdata.main" --minscale 1 --maxscale 5  --executortype newdeploy
```

And remember to create route to that function
```bash
fission route create --function reqdatapy --url /reqdatapy --method [GET/POST/...]
```

Then test with `curl` or with fission-cli (suppose we use POST method here):
```bash
curl -d '{"key1":"value"}' -H "Content-Type: application/json" -X POST $FISSION_ROUTER/reqdatapy

fission fn test --method POST -b '{"key1":"value"}' --name reqdatapy
```

## Customized Docker Image and Binary Environment
Instead of using `fission/binary-env`, we can compile our own image and create
Fission environment based on that.
We can modify Fission's [binary environment](https://github.com/fission/fission/tree/master/environments/binary).
Then build our own image:
```bash
sudo docker build --tag=<docker userid>/binary-env .
sudo docker push <docker userid>/binary-env
```
Note that we need newer version of docker. Because older versions cannot support
multi-stage build.

After that, we can use this new environment! Refer to [binary example](https://github.com/fission/fission/tree/master/examples/binary):
```bash
# Upload the function to fission
fission function create --name echo --env binary-env --code echo.sh

# Map /hello to the hello function
fission route create --method POST --url /echo --function echo

# Run the function
curl -XPOST -d 'Echoooooo!'  http://$FISSION_ROUTER/echo
```
Similarly, you can create a function with `--code hello.sh` and test.

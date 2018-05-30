# Fission

## Preparation

### Installation Guide
The original documentation is [here](https://docs.fission.io/0.7.2/installation/installation/).
You first need to set up a running kubernetes luster. Fission requires at least
Kubernetes 1.6.

#### Helm
Install helm
```
curl -LO https://storage.googleapis.com/kubernetes-helm/helm-v2.7.0-linux-amd64.tar.gz
tar xzf helm-v2.7.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin
```

To avoid RBAC related issue, we need to install helm using a dedicated service
accaount:
```
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller --upgrade
```

#### Install Fission

##### Use Fission public release
It is pretty simple to use their release packet:
```
helm install --namespace fission https://github.com/fission/fission/releases/download/0.7.2/fission-all-0.7.2.tgz
```
The fission namespace in Kubernetes is `fission`, and the functions namespace is `fission-function`.

##### Build from scratch
If you changed some files inside fission and wanted to re-compile and install fission,
you can follow the instructions [here](https://docs.fission.io/0.7.2/installation/installation/).
But that instruction is not 100% correct. Here are my experiences:  
1. Install `go` (I installed go version 1.10)  
2. Install `glide`  
    ```
    sudo add-apt-repository ppa:masterminds/glide && sudo apt-get update
    sudo apt-get install glide
    ```  
3. Clone fission to your `$GOPATH/src/github.com/fission/fission`
    You can put our submodule `fission` to that directory.  
    ```
    cd $GOPATH/src/github.com/fission/fission
    glide install -v
    ```  
4. Build fission server and an image. Change the docker hub account to your
    own account, don't push to `fission` account. And remember to pass the
    version tag, otherwise, pods cannot find correct images.  
    ```
    pushd fission-bundle
    sudo ./push.sh 0.7.2
    ```  
5. Finally, use helm to install fission. Run command from top fission directory.  
    ```
    helm install --set "image=<docker hub name>/fission-bundle,pullPolicy=IfNotPresent,analytics=false" charts/fission-all --namespace fission
    ```  
6. If you want to update CLI too, build with (from top fission directory):  
    ```
    cd fission && go install
    ```

#### Install Fission CLI
On a remote/master machine, you can install the CLI by using their release download.
```
curl -Lo fission https://github.com/fission/fission/releases/download/0.7.2/fission-cli-linux && chmod +x fission && sudo mv fission /usr/local/bin/
```

#### Working remotely
By default, fission CLI only works for local deployment. Howerver, you can specify
the `--server` option in CLI commands to be the remote controller URL.
In order to use Fission from a remote client, you need to expose the controller
to a public TCP port!

On your kubernetes master node:
```
kubectl expose service controller --type=LoadBalancer --name=controller-open --namespace=fission --port=31112 --target-port=8888
```

Then check the public port for `controller-open` service:
```
kubectl get services --namespace=fission
```
> controller-open   LoadBalancer   ...   31112:<controller-port>/TCP  
> router            LoadBalancer   ...   80:<router-port>/TCP


On the remote client, set environmental variable:
```
export FISSION_URL=<remote-ip>:<controller-port>
export FISSION_ROUTER=<remote-ip>:<router-port>
```

Or you can pass `--server` option manually for each command:
```
fission --server=<remote-ip>:<controller-prot> ...
```

## Hello World Node.js example

This example derived from the [original site](https://docs.fission.io/0.7.2/usage/functions/).
1. You need to create an environment for that language (node.js here).
    On your server, or on your configured remote client.
    We are going to create an environment named `node`.
    ```
    fission env create --name node --image fission/node-env:0.4.0 \
        --mincpu 40 --maxcpu 80 --minmemory 64 --maxmemory 128 --poolsize 4 
    ```
    Then you can view environment information:
    ```
    fission env list
    ```
    This same environment can support many functions!

2. Then you can create your own function, we use [hello.js](hello.js) as an example.
    Let’s create a route for the function which can be used for making HTTP requests:
    ```
    fission route create --function hello --url /hello
    ```

    Then create a function based on pool based executor.
    ```
    fission fn create --name hello --code hello.js --env node --executortype poolmgr
    ```

3. Test the function by hitting its URL:
    ```
    curl http://$FISSION_ROUTER/hello
    ```

4. Similarly you can create a new deployment executor type function and provide minmum and maximum scale for the function.
    ```
    fission fn create --name hello --code hello.js --env node --minscale 1 --maxscale 5  --executortype newdeploy
    ```

5. If you need to update a function:
    ```
    fission fn update --name hello --code ../hello.js
    ```

## Fission Auto Scaling

In order to make HPA work, you need to start metrics server:
```
git clone https://github.com/kubernetes-incubator/metrics-server.git
cd metrics-server
kubectl create -f deploy/1.8+/
```

Then create a new function called `hello2`.
```
fission route create --function hello --url /hello2

fission fn create --name hello2 --env node --code hello.js --minmemory 64 --maxmemory 128 --minscale 1 --maxscale 6 --executortype newdeploy --targetcpu 50
```

Use `hey` to generate load. Note that hey only works for go version 1.7+
```
hey -c 250 -n 10000 http://$FISSION_ROUTER/hello2
```

Then watch the scaling effect by:
```
kubectl get hpa -n fission-function -w
```

## Fissioin builds/compiled functions
Fission allows us to deploy more complicated function packets.

### From source
Based on original [post](https://docs.fission.io/0.7.2/usage/functions/#building-function-from-source),
The source code is at [sourcepkg](sourcepkg).

1. Create an environment with env image and python-builder image.
    ```
    fission env create --name python --image fission/python-env --builder fission/python-builder:latest --mincpu 40 --maxcpu 80 --minmemory 64 --maxmemory 128 --poolsize 2
    ```

2. Then zip the directory and create the function & route
    ```
    zip -jr demo-src-pkg.zip sourcepkg/
    fission fn create --name hellopy --env python --src demo-src-pkg.zip  --entrypoint "user.main" --buildcmd "./build.sh"
    fission route create --function hellopy --url /hellopy
    ```

3. You can check logs of the builder in `fission-builder` namespace:
    ```
    kubectl -n fission-builder logs -f <pod id> builder
    ```
    After the build process is succeeded, we can use that function as normal.

### From compiled package
Similar to AWS Lambda, we can deploy a pre-built deployment package to Fission.
The [documentation](https://docs.fission.io/0.7.2/usage/functions/#using-compiled-artifacts-with-fission)
has instructions to do that.

1. Create an environment with env image and python-builder image.
    ```
    fission env create --name python --image fission/python-env --builder fission/python-builder:latest --mincpu 40 --maxcpu 80 --minmemory 64 --maxmemory 128 --poolsize 2
    ```

2. Then zip the directory and create the function & route
    ```
    zip -jr demo-deploy-pkg.zip testDir/
    fission fn create --name hellopy --env python --deploy demo-deploy-pkg.zip --entrypoint "hello.main"
    fission route create --function hellopy --url /hellopy
    ```

3. Then we can test that function as usual.
    ```
    fission fn test --name hellopy
    ```

4. Or view the logs of that function (must on the server machine).
    ```
    fission fn logs --name hellopy
    ```

For more information about packaging source code, please refer to Fission official
[webpage](https://docs.fission.io/0.7.2/usage/package/).

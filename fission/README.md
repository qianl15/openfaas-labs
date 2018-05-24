# Fission

## Preparation
In order to use Fission from a remote client, you need to expose the controller
to a public TCP port!

On your kubernetes master node:
```
kubectl expose service controller --type=LoadBalancer --name=controller-open --namespace=fission --port=31112 --target-port=8888
```

Then check the public port for `controller-open` service:
```
kubectl get services --namespace=fission

>
controller-open   LoadBalancer   ...   31112:<controller-port>/TCP
```

On the remote client, set environmental variable:
```
export FISSION_URL=<remote-ip>:<controller-port>
export FISSION_ROUTER=<remote-ip>:32268
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

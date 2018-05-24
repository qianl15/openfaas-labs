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
```

On the remote client, set environmental variable:
```
export FISSION_URL=<remoteip>:<controller port>
export FISSION_ROUTER=<remote-ip>:32268
```

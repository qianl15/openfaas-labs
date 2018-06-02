# test-executable example

This is an example benchmark for Fission.

## How to use it?
1. Compile to get a deploy package, including the scripts and the static binary.
    ```bash
    ./build.sh
    ```
2. Deploy a Fission function:
    ```bash
    fission fn create --name helloexe --env python3-env --deploy exe-test.zip --entrypoint "fission_function.main" --minscale 1 --maxscale 5  --executortype newdeploy
    ```
3. Test it:
    ```bash
    fission fn test --name helloexe -b "test"
    ```

Note that the compiled package is larger than 256KB, which means Fission cannot
use plain text to transfer it. Therefore, this function must be deployed from
one of the machines in the kubernetes cluster (either master or other nodes
would be fine).

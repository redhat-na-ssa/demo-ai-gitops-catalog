# ovms-operator

OpenVINO Toolkit Operator manages OpenVINO components in OpenShift.

Currently there available components are ModelServer and Notebook.

# Model Server
[OpenVINO™ Model Server](https://github.com/openvinotoolkit/model_server) (OVMS) is a scalable, high-performance solution for serving machine learning models optimized for Intel® architectures. The server provides an inference service via gRPC or REST API for any models trained in a framework that is supported by [OpenVINO](https://software.intel.com/en-us/openvino-toolki://docs.openvino.ai/latest/index.html).
Model Server configuration parameters is explained [here](https://github.com/openvinotoolkit/operator/blob/main/docs/modelserver_params.md).
## Using the cluster
OpenVINO Model Server can be consumed as a `Service`. It is called like with `ModelServer` resource with `-ovms` suffix.
The suffix is ommited when `ovms` phrase is included in the name.
The service exposes gRPC and REST API interfaces to run inference requests.
```
oc get pods
NAME                                        READY   STATUS    RESTARTS   AGE
model-server-sample-ovms-586f6f76df-dpps4   1/1     Running   0          8h

oc get services
NAME                       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
model-server-sample-ovms   ClusterIP   172.25.199.210   <none>        8080/TCP,8081/TCP   8h
```

# Notebook
The Notebook resource integrates JupyterHub from OpenShift Data Science or Open Data Hub with a container image that includes [developer
tools](https://github.com/openvinotoolkit/openvino/blob/master/docs/install_guides/pypi-openvino-dev.md)
from the OpenVINO toolkit and a set of Jupyter notebook tutorials. It enables selecting a defined image `OpenVINO™ Toolkit` from
the Jupyter Spawner choice list.

Create the `Notebook` resource in the same project with JupyterHub and RedHat OpenShift Data Science operator as seen in [documentation](https://github.com/openvinotoolkit/operator/blob/main/docs/notebook_in_rhods.md).
It builds the image in the cluster based on Dockerfile from [openvino_notebooks](https://github.com/openvinotoolkit/openvino_notebooks).

## References
OpenVINO Model Server on [Github](https://github.com/openvinotoolkit/model_server)

OpenVINO Model Server Operator on [Github](https://github.com/openvinotoolkit/operator)

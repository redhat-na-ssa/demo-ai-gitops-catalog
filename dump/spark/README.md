# Spark on OpenShift Notes

- https://github.com/bkoz/spark
- https://github.com/kubeflow/spark-operator

Deploy Helm

```sh
helm repo add spark-operator https://kubeflow.github.io/spark-operator
helm repo update

helm upgrade -i spark-operator spark-operator/spark-operator \
    --namespace spark-operator \
    --create-namespace \
    --values helm-spark.yaml
```

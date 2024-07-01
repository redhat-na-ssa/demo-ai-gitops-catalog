# Deploy Weaviate on OCP

## Quickstart

```
helm repo add weaviate https://weaviate.github.io/weaviate-helm

NS=$(oc project -q)

helm upgrade --install "weaviate" weaviate/weaviate \
  --namespace ${NS} \
  --values values.yaml

oc expose service/weaviate
```

## Links

- https://github.com/bkoz/weaviate
- https://github.com/weaviate/weaviate-helm
- [Helm default values](https://github.com/weaviate/weaviate-helm/blob/master/weaviate/values.yaml)

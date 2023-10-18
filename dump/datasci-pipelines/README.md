# KFP Tekton

## Issues

The pipeline service does not allow the setup of non secure s3 endpoints by default

```
spec:
  objectStorage:
    externalStorage:
      secure: false
```

```
oc patch DataSciencePipelinesApplication \
  pipelines-definition \
  --type merge \
  --patch '{"spec":{"objectStorage":{"externalStorage":{"secure": false }}}}'
```

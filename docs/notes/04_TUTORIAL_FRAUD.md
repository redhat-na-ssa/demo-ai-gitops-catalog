# Notes - Template

State your goal

per [docs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/openshift_ai_tutorial_-_fraud_detection_example)

- [ ] Create workbench
- [ ] Clone in repo
- [ ] Train model
- [ ] Store model 
- [ ] Deploy the model on a single-model server
- [ ] Deploy the model on a multi-model server
- [ ] Configure Token authorization w/ service account
- [ ] Test the inference API via Terminal
- [ ] Build training with Elyra
    - Launch Elyra pipeline editor
    - Configure pipeline properties for the nodes
    - Drag the objects on the Elyra canvas
    - Configure the Node Properties for File Dependencies
    - Configure the data connection for the Node using Kubernetes Secrets
    - Execute the DAG from the pipeline editor
    - Inspect the Run Details 
    - [ ] Schedule the pipeline to run once
    - [ ] Schedule the pipeline to run on a schedule
- [ ] Build training with kfp SDK
    - [ ] Import Pipeline coded with kfp SDK

## Links

- [Docs - Link]()
- [Blog - Link]()

## Checklist

- [ ] Step 1
  - [ ] Step 1.a

## Details / Notes

```sh
# run shell commands

```

### Issues

[Reference](ISSUES.md) - [Jira](linktojira)

### Kustomized Code

[Code](../../components/configs/kustomized/rhods-config/)

### Rollback / Uninstall

```sh
oc delete -k components/configs/kustomized/rhods-config
```

# Console Customization

Custom 503 error

[OCP Custom Ingress Errors](https://docs.openshift.com/container-platform/4.10/networking/ingress-operator.html#nw-customize-ingress-error-pages_configuring-ingress)

```
oc apply -f components/configs/console/base/error-pages-custom-cm.yaml
oc patch -n openshift-ingress-operator ingresscontroller/default --patch '{"spec":{"httpErrorCodePages":{"name":"error-pages-custom"}}}' --type=merge
```

```
oc apply -f components/configs/console/base/error-pages-normal-cm.yaml
oc patch -n openshift-ingress-operator ingresscontroller/default --patch '{"spec":{"httpErrorCodePages":{"name":"error-pages-normal"}}}' --type=merge
```

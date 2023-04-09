# Console Customization

[OCP Custom Ingress Errors](https://docs.openshift.com/container-platform/4.10/networking/ingress-operator.html#nw-customize-ingress-error-pages_configuring-ingress)
[OCP Custom Console](https://docs.openshift.com/container-platform/4.10/web_console/customizing-the-web-console.html)

Custom 404, 503 error

```
oc apply -f components/configs/console/base/error-pages-custom-cm.yaml
oc patch -n openshift-ingress-operator ingresscontroller/default --patch '{"spec":{"httpErrorCodePages":{"name":"error-pages-custom"}}}' --type=merge
```

```
# oc apply -f components/configs/console/base/error-pages-normal-cm.yaml
# oc patch -n openshift-ingress-operator ingresscontroller/default --patch '{"spec":{"httpErrorCodePages":{"name":"error-pages-normal"}}}' --type=merge
oc patch -n openshift-ingress-operator ingresscontroller/default --patch '{"spec":{"httpErrorCodePages":{"name":""}}}' --type=merge
```

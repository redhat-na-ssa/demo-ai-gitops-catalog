# Console Customization

Custom 503 error

[OCP Custom Ingress Errors](https://docs.openshift.com/container-platform/4.10/networking/ingress-operator.html#nw-customize-ingress-error-pages_configuring-ingress)

```
oc apply -f components/configs/console/base/custom-error-pages-cm.yaml
oc patch -n openshift-ingress-operator ingresscontroller/default --patch '{"spec":{"httpErrorCodePages":{"name":"custom-error-pages"}}}' --type=merge
```

[OCP Custom Console](https://docs.openshift.com/container-platform/4.10/web_console/customizing-the-web-console.html)

```
oc adm create-login-template > components/configs/console/base/login.html
oc adm create-provider-selection-template > components/configs/console/base/providers.html
oc adm create-error-template > components/configs/console/base/errors.html
```

```
oc create secret generic login-template --from-file=login.html -n openshift-config
oc create secret generic providers-template --from-file=providers.html -n openshift-config
oc create secret generic error-template --from-file=errors.html -n openshift-config
```

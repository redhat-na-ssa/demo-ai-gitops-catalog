# Console Customization

Custom 503 error

[OCP Custom Ingress Errors](https://docs.openshift.com/container-platform/4.10/networking/ingress-operator.html#nw-customize-ingress-error-pages_configuring-ingress)

```
oc apply -f components/configs/console/files/error-pages-custom-cm.yaml
oc patch -n openshift-ingress-operator ingresscontroller/default --patch '{"spec":{"httpErrorCodePages":{"name":"error-pages-custom"}}}' --type=merge
```

```
oc apply -f components/configs/console/files/error-pages-normal-cm.yaml
oc patch -n openshift-ingress-operator ingresscontroller/default --patch '{"spec":{"httpErrorCodePages":{"name":"error-pages-normal"}}}' --type=merge
```

[OCP Custom Console](https://docs.openshift.com/container-platform/4.10/web_console/customizing-the-web-console.html)

```
oc adm create-login-template > components/configs/console/files/login.html
oc adm create-provider-selection-template > components/configs/console/files/providers.html
oc adm create-error-template > components/configs/console/files/errors.html
```

```
oc create secret generic login-template --from-file=login.html -n openshift-config
oc create secret generic providers-template --from-file=providers.html -n openshift-config
oc create secret generic error-template --from-file=errors.html -n openshift-config
```

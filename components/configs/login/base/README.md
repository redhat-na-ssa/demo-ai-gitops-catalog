# Login Console Customization

[OCP Custom Console](https://docs.openshift.com/container-platform/4.10/web_console/customizing-the-web-console.html)

```
oc adm create-login-template > components/configs/login/base/login.html
oc adm create-provider-selection-template > components/configs/login/base/providers.html
oc adm create-error-template > components/configs/login/base/errors.html
```

```
oc create secret generic login-template --from-file=components/configs/login/base/login.html -n openshift-config
oc create secret generic providers-template --from-file=components/configs/login/base/providers.html -n openshift-config
oc create secret generic error-template --from-file=components/configs/login/base/errors.html -n openshift-config
```

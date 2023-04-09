# Login Console Customization

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

# Login Console Customization

[OCP Custom Console](https://docs.openshift.com/container-platform/4.10/web_console/customizing-the-web-console.html)

Follow the docs

```
oc adm create-login-template > login.html
oc adm create-provider-selection-template > providers.html
oc adm create-error-template > errors.html
```

```
oc create secret generic login-template --from-file=login.html -n openshift-config
oc create secret generic providers-template --from-file=providers.html -n openshift-config
oc create secret generic error-template --from-file=errors.html -n openshift-config
```

```
spec:
  templates:
    value:
      error:
        name: error-template
      login:
        name: login-template
      providerSelection:
        name: providers-template
```

Dump current configuration

```
pushd components/configs/login/base
oc exec deployment/oauth-openshift -- cat /var/config/system/secrets/v4-0-config-system-ocp-branding-template/login.html > login.html
oc exec deployment/oauth-openshift -- cat /var/config/system/secrets/v4-0-config-system-ocp-branding-template/errors.html > errors.html
oc exec deployment/oauth-openshift -- cat /var/config/system/secrets/v4-0-config-system-ocp-branding-template/providers.html > providers.html
popd
```

Apply custom login template

```
pushd components/configs/login/base
oc -n openshift-config \
  create secret generic login-custom \
  --from-file=login.html \
  --from-file=providers.html \
  --from-file=errors.html
popd
```

```
spec:
  templates:
    value:
      error:
        name: login-custom
      login:
        name: login-custom
      providerSelection:
        name: login-custom
```

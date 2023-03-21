# Identity Management

## GitHub Authentication

If your cluster domain has changed you will need to update the Oauth callback URL.

1. Go to: [NA-SSA Apps](https://github.com/organizations/redhat-na-ssa/settings/applications/), [OCP Oauth](https://github.com/organizations/redhat-na-ssa/settings/applications/2086423)
1. Update the `Authorization callback URL` '<https://oauth-openshift.apps.[cluster> name].[domain name]/oauth2callback/GitHub'
1. Click `Update Application`

Add a login to htpasswd

```
cat << YAML | > scratch/htpasswd-secret.yaml
kind: Secret
apiVersion: v1
metadata:
  name: htpasswd-secret
  namespace: openshift-config
  annotations:
    managed-by: argocd.argoproj.io
stringData:
  htpasswd: |
    # managed by argocd
    #
    # add a password with the following
    # NOTE: the leading extra space so you do not leave a password in shell history
    #  PASSWORD=alongsecret
    # echo -n "$PASSWORD" | htpasswd -inB opentlc-mgr

    opentlc-mgr:asecrethashwillgohere
YAML

  PASSWORD=alongsecret
echo -n "$PASSWORD" | htpasswd -inB username >> scratch/htpasswd-secret.yaml
```

Turn your secret into a sealed secret for git

```
cat scratch/htpasswd-secret | \
  kubeseal \
    -o yaml \
    --controller-namespace sealed-secrets > scratch/htpasswd-secret-ss.yaml
```

## Links

- [Identity Provider Examples](https://github.com/kenmoini/openshift-identity-crisis)

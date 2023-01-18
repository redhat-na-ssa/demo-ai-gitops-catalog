# Identity Management

## GitHub Authentication

If your cluster domain has changed you will need to update the Oauth callback URL.

1. Go to: [NA-SSA Apps](https://github.com/organizations/redhat-na-ssa/settings/applications/), [OCP Oauth](https://github.com/organizations/redhat-na-ssa/settings/applications/2086423)
1. Update the `Authorization callback URL` 'https://oauth-openshift.apps.[cluster name].[domain name]/oauth2callback/GitHub'
1. Click `Update Application`

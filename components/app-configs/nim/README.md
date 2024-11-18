# Notes

You need an NCR API Key to pull container images and models.
It will need to be setup for the default SA in the namespace.

## Quickstart

Query NIM Open AI API

```sh
URL=https://$(oc get route -o go-template='{{.spec.host}}' nim)/v1/completions

curl -s -X 'POST' \
  "${URL}" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
      "model": "meta/llama3-8b-instruct",
      "prompt": "Once upon a time",
      "max_tokens": 64
    }' | jq .choices[0].text
```

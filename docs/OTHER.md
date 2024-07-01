# Other Notes

## Policy on k8s

- https://github.com/open-policy-agent/gatekeeper
- https://kyverno.io

## SOPS

https://github.com/getsops/sops

## AWS Machine Set storage

Patch `MachineSet` to add secondary storage

```sh
spec:
  template:
    spec:
      providerSpec:
        value:
          blockDevices:
            - ebs:
                encrypted: true
                iops: 0
                kmsKey:
                  arn: ''
                volumeSize: 100
                volumeType: gp3
            - deviceName: /dev/xvdb
              ebs:
                encrypted: true
                iops: 0
                kmsKey:
                  arn: ''
                volumeSize: 1000
                volumeType: gp3
```

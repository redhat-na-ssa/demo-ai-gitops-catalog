# Setup AWS Controllers for Kubernetes / ACK Operators

Create AWS users (service principles)

NOTICE: Keep output from `aws iam create-access-key ...`

```sh
# create s3 user
aws iam create-user --user-name ack-user-s3
aws iam create-access-key --user-name ack-user-s3
```

```sh
# create sagemaker user
aws iam create-user --user-name ack-user-sagemaker
aws iam create-access-key --user-name ack-user-sagemaker
```

Assign Amazon Resource Name (ARN) policy to users

```sh
# attach user policy - s3
aws iam attach-user-policy \
    --user-name ack-user-s3 \
    --policy-arn 'arn:aws:iam::aws:policy/AmazonS3FullAccess'
```

```sh
# attach user policy - sagemaker (ec2,sagemaker)
aws iam attach-user-policy \
    --user-name ack-user-sagemaker \
    --policy-arn  'arn:aws:iam::aws:policy/AmazonSageMakerFullAccess'
```

## Links

- [AWS Controllers for Kubernetes (ACK) - Docs](https://aws-controllers-k8s.github.io/community/docs/community/overview/)
- [ACK in Openshift - Docs](https://aws-controllers-k8s.github.io/community/docs/user-docs/openshift)
- [IAM Policy - S3](https://github.com/aws-controllers-k8s/s3-controller/blob/main/config/iam/recommended-policy-arn)
- [IAM Policy - Sagemaker](https://github.com/aws-controllers-k8s/sagemaker-controller/blob/main/config/iam/recommended-policy-arn)
- [IAM Delete User - Docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_remove.html)

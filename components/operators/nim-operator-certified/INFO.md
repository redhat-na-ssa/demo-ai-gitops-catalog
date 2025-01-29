# nim-operator-certified

## About this Operator
The NVIDIA NIM Operator is a Kubernetes operator designed to facilitate the deployment, management, and scaling of NVIDIA NeMo (Neural Modules) services on Kubernetes clusters. NeMo is a toolkit for building, training, and fine-tuning state-of-the-art deep learning models for a variety of applications, including speech recognition, natural language processing (NLP), and text-to-speech synthesis. The NeMo Operator streamlines the integration of these powerful AI capabilities into cloud-native environments such as Kubernetes, leveraging NVIDIA GPUs.

## Prerequisites for enabling this Operator
* Install NVIDIA GPU Operator * Install CSI Driver or Local Path Provisioner * Create necessary ImagePullSecret and NGC Auth Secrets
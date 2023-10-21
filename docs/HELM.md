# helm

Download helm chart locally and dump yaml

```
mkdir -p scratch/yaml
cd scratch

helm fetch --untar --untardir . 'rh-ecosystem-edge/console-plugin-nvidia-gpu' 
helm template --output-dir './yaml' './console-plugin-nvidia-gpu'
```

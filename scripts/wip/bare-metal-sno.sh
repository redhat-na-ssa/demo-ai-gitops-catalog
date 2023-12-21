#!/bin/bash

download_openshift-baremetal-install(){
  export VERSION=stable-4.12
  export RELEASE_IMAGE=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$VERSION/release.txt | grep 'Pull From: quay.io' | awk -F ' ' '{print $3}')

  export cmd=openshift-baremetal-install
  export pullsecret_file=./pull-secret.txt
  export extract_dir=$(pwd)

  oc adm release extract \
  --registry-config "${pullsecret_file}" \
  --command="${cmd}" \
  --to "${extract_dir}" "${RELEASE_IMAGE}"
}


download_openshift_install_bins(){
  VERSION=4.12
  curl -LOC - https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.12/latest/rhcos-4.12.30-x86_64-live.x86_64.iso
  curl -LC - https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/coreos-installer/latest/coreos-installer_amd64 -o coreos-installer
  chmod +x coreos-installer
}

ocp_install_create_config(){
cat << YAML > install-config.yaml
apiVersion: v1
baseDomain: kow.lab
metadata:
  name: ocp
networking:
  machineNetwork:
  - cidr: 10.0.0.0/24
  # networkType: OpenShiftSDN
compute:
- name: worker
  replicas: 1
controlPlane:
  name: master
  replicas: 1
  platform:
    baremetal: {}
platform:
  baremetal:
    apiVIP: 10.0.0.155
    ingressVIP: 10.0.0.156
    bootstrapOSImage: BOOTSTRAPOSIMAGE
    provisioningNetwork: Disabled
    externalBridge: "baremetal"
    hosts:
      - name: sno-bm
        role: master
        bmc:
          # address: ipmi://10.0.0.111:623
          address: redfish-virtualmedia://10.0.0.111:8888/redfish/v1/Systems/sno-bm
          disableCertificateVerification: True
          username: admin
          password: secure_password
        bootMACAddress: 52:54:00:cb:ce:00
        rootDeviceHints:
         deviceName: "/dev/vda"
        # bootMode: legacy
        bootMode: UEFI
      - name: kvm-00
        role: worker
        bmc:
          # address: ipmi://{{ host.vbmc_ip }}:{{ host.vbmc_port }}
          address: redfish-virtualmedia://10.0.0.111:8888/redfish/v1/Systems/kvm-00
          disableCertificateVerification: True
          username: admin
          password: secure_password
        bootMACAddress: 52:54:00:cb:cf:00
        rootDeviceHints:
         deviceName: "/dev/vda"
        bootMode: UEFI
pullSecret: ''
sshKey: ''
bootstrapInPlace: 
  InstallationDisk: <boot-disk>
YAML
}

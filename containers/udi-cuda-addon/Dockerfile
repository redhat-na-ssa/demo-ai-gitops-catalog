FROM quay.io/devfile/base-developer-image:ubi8-latest
USER 0
# FROM registry.access.redhat.com/ubi8/python-38

ARG RELEASE
ARG DATE

LABEL name="workbench-images:base-ubi8-py38_${RELEASE}_${DATE}" \
    summary="UBI8-Python 3.8 base for workbench images" \
    description="UBI8-Python 3.8 base for workbench images" \
    io.k8s.description="UBI8-Python 3.8 base for workbench images" \
    io.k8s.display-name="UBI8-Python 3.8 base for workbench images for ODH or RHODS" \
    authoritative-source-url="https://github.com/opendatahub-io-contrib/workbench-images" \
    io.openshift.build.commit.ref="${RELEASE}" \
    io.openshift.build.source-location="https://github.com/opendatahub-io-contrib/workbench-images/jupyter/base/ubi8" \
    io.openshift.build.image="https://quay.io/opendatahub-contrib/workbench-images:base-ubi8-py38_${RELEASE}_${DATE}"

# This will avoid people forgetting to set no-cache-dir when building images
ENV PIP_NO_CACHE_DIR=1

USER 0

# Update base image for latest security updates
# (ubi images are not released that often)
RUN dnf -y --setopt=tsflags=nodocs update && \
    dnf -y clean all --enablerepo='*'
#
# BK - install python
#
RUN yum install -y python38 
RUN alternatives --set python /usr/bin/python3.8

USER 1001

# Install micropipenv to deploy packages from Pipfile.lock
# RUN pip install -U "micropipenv[toml]"

WORKDIR /opt/app-root/bin

# Copy files
# COPY Pipfile.lock ./

# Install packages and cleanup
# (all commands are chained to minimize layer size)
# RUN echo "Installing softwares and packages" && \
    # Install oc client \
#     curl -L https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz \
#         -o /tmp/openshift-client-linux.tar.gz && \
#     tar -xzvf /tmp/openshift-client-linux.tar.gz oc && \
#     rm -f /tmp/openshift-client-linux.tar.gz && \
    # Install Python packages \
#     micropipenv install && \
#     rm -f ./Pipfile.lock && \
    # Fix permissions to support pip in Openshift environments \
#     chmod -R g+w /opt/app-root/lib/python3.8/site-packages && \
#     fix-permissions /opt/app-root -P

WORKDIR /opt/app-root/src

#################
ARG BASE_IMAGE
# FROM ${BASE_IMAGE}

ENV NVARCH x86_64
ENV NVIDIA_REQUIRE_CUDA "cuda>=11.8 brand=tesla,driver>=450,driver<451 brand=tesla,driver>=470,driver<471 brand=unknown,driver>=470,driver<471 brand=nvidia,driver>=470,driver<471 brand=nvidiartx,driver>=470,driver<471 brand=geforce,driver>=470,driver<471 brand=geforcertx,driver>=470,driver<471 brand=quadro,driver>=470,driver<471 brand=quadrortx,driver>=470,driver<471 brand=titan,driver>=470,driver<471 brand=titanrtx,driver>=470,driver<471 brand=unknown,driver>=510,driver<511 brand=nvidia,driver>=510,driver<511 brand=nvidiartx,driver>=510,driver<511 brand=geforce,driver>=510,driver<511 brand=geforcertx,driver>=510,driver<511 brand=quadro,driver>=510,driver<511 brand=quadrortx,driver>=510,driver<511 brand=titan,driver>=510,driver<511 brand=titanrtx,driver>=510,driver<511 brand=unknown,driver>=515,driver<516 brand=nvidia,driver>=515,driver<516 brand=nvidiartx,driver>=515,driver<516 brand=geforce,driver>=515,driver<516 brand=geforcertx,driver>=515,driver<516 brand=quadro,driver>=515,driver<516 brand=quadrortx,driver>=515,driver<516 brand=titan,driver>=515,driver<516 brand=titanrtx,driver>=515,driver<516"
ENV NV_CUDA_CUDART_VERSION 11.8.89-1

USER 0

COPY cuda.repo-x86_64 /etc/yum.repos.d/cuda.repo

RUN NVIDIA_GPGKEY_SUM=d0664fbbdb8c32356d45de36c5984617217b2d0bef41b93ccecd326ba3b80c87 && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/rhel8/${NVARCH}/D42D0685.pub | sed '/^Version/d' > /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA && \
    echo "$NVIDIA_GPGKEY_SUM  /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA" | sha256sum -c --strict -

ENV CUDA_VERSION 11.8.0

# For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a
RUN yum upgrade -y && yum install -y \
    cuda-cudart-11-8-${NV_CUDA_CUDART_VERSION} \
    cuda-compat-11-8 \
    && ln -s cuda-11.8 /usr/local/cuda \
    && yum clean all \
    && rm -rf /var/cache/yum/*

# nvidia-docker 1.0
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

COPY NGC-DL-CONTAINER-LICENSE /

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility

USER 1001
##################
ARG BASE_IMAGE
# FROM ${BASE_IMAGE}

ENV NV_CUDA_LIB_VERSION 11.8.0-1

ENV NV_NVTX_VERSION 11.8.86-1
ENV NV_LIBNPP_VERSION 11.8.0.86-1
ENV NV_LIBNPP_PACKAGE libnpp-11-8-${NV_LIBNPP_VERSION}
ENV NV_LIBCUBLAS_VERSION 11.11.3.6-1
ENV NV_LIBNCCL_PACKAGE_NAME libnccl
ENV NV_LIBNCCL_PACKAGE_VERSION 2.15.5-1
ENV NV_LIBNCCL_VERSION 2.15.5
ENV NCCL_VERSION 2.15.5
ENV NV_LIBNCCL_PACKAGE ${NV_LIBNCCL_PACKAGE_NAME}-${NV_LIBNCCL_PACKAGE_VERSION}+cuda11.8

USER 0

RUN yum install -y \
    cuda-libraries-11-8-${NV_CUDA_LIB_VERSION} \
    cuda-nvtx-11-8-${NV_NVTX_VERSION} \
    ${NV_LIBNPP_PACKAGE} \
    libcublas-11-8-${NV_LIBCUBLAS_VERSION} \
    ${NV_LIBNCCL_PACKAGE} \
    && yum clean all \
    && rm -rf /var/cache/yum/*

USER 1001
#######
ARG BASE_IMAGE
# FROM ${BASE_IMAGE}

ENV NV_CUDNN_VERSION 8.6.0.163-1
ENV NV_CUDNN_PACKAGE libcudnn8-${NV_CUDNN_VERSION}.cuda11.8

LABEL com.nvidia.cudnn.version="${NV_CUDNN_VERSION}"

USER 0

RUN yum install -y \
    ${NV_CUDNN_PACKAGE} \
    && yum clean all \
    && rm -rf /var/cache/yum/*

USER 1001


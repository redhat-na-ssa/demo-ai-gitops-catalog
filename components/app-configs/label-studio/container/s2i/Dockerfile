FROM registry.access.redhat.com/ubi8/python-311

ENV LS_DIR=/opt/app-root/src \
    HOME=/opt/app-root/src

WORKDIR ${LS_DIR}

# copy and install dependencies
COPY --chown=1001:0 requirements.txt .

# hadolint ignore=DL3013
RUN pip3 install --no-cache-dir -U pip setuptools wheel && \
    pip3 install --no-cache-dir -r requirements.txt

COPY --chown=1001:0 entrypoint.sh /opt/app-root/bin

ENV DJANGO_SETTINGS_MODULE=core.settings.label_studio \
    LABEL_STUDIO_BASE_DATA_DIR=${LS_DIR}/data \
    OPT_DIR=${LS_DIR}/etc \
    SETUPTOOLS_USE_DISTUTILS=stdlib

EXPOSE 8080

LABEL name="Label Studio" \
  maintainer="TBD" \
  vendor="Human Signal" \
  summary="LabelStudio" \
  description="Label Studio is an open source data labeling tool."

ENTRYPOINT ["/opt/app-root/bin/entrypoint.sh"]
CMD ["label-studio"]
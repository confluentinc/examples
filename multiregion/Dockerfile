ARG REPOSITORY
ARG IMAGE
ARG CP_VERSION

FROM $REPOSITORY/$IMAGE:$CP_VERSION

USER root
RUN yum install -y \
     libmnl \
     which
RUN wget http://vault.centos.org/8.1.1911/BaseOS/x86_64/os/Packages/iproute-tc-4.18.0-15.el8.x86_64.rpm
RUN rpm -i --nodeps --nosignature http://vault.centos.org/8.1.1911/BaseOS/x86_64/os/Packages/iproute-tc-4.18.0-15.el8.x86_64.rpm
USER appuser

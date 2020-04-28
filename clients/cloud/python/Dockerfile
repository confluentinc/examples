FROM ubuntu:18.04

#ENV SASL_MECHANISMS="PLAIN"
#ENV SECURITY_PROTOCOL="SASL_SSL"

RUN apt-get update && \
    apt-get install -y python3 python3-pip curl vim
RUN pip3 install -U confluent-kafka
RUN pip3 install -U confluent-kafka[avro]
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10

ARG CONFIGFILE

COPY *.py ./
COPY $CONFIGFILE ./


FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y python3 python3-pip curl vim

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -U -r /tmp/requirements.txt

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10

COPY *.py ./

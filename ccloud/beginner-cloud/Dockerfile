FROM maven:3.6.3-jdk-11
WORKDIR /tmp/java
COPY pom.xml .
COPY src/ /tmp/java/src/
RUN mvn compile
USER root
# Update apt-get and install iptables
RUN apt-get update && apt-get install -y iptables
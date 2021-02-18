FROM maven:3.6.3-jdk-11-slim
# Update apt-get and install iptables
RUN apt-get update && apt-get install -y iptables
WORKDIR /tmp/java
COPY pom.xml .
RUN  mvn dependency:resolve
COPY src/ /tmp/java/src/
RUN mvn compile

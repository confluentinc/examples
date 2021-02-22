FROM maven:3.6.3-jdk-11-slim
# Update apt-get and install iptables
RUN apt-get update && apt-get install -y iptables git
# Add pom and checkstyle suppressions to cache dependencies
WORKDIR /tmp/java
COPY pom.xml .
COPY checkstyle/suppressions.xml /tmp/java/checkstyle/suppressions.xml
COPY checkstyle.xml /tmp/java/checkstyle.xml
RUN  mvn verify --fail-never
# Copy in java src code
COPY src/ /tmp/java/src/

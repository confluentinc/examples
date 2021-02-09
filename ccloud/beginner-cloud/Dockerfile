FROM maven:3.6.3-jdk-11
WORKDIR /tmp/java
COPY pom.xml .
COPY src/ /tmp/java/src/
RUN mvn compile
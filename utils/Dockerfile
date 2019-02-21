FROM alpine:3.4
WORKDIR /db
ADD customers.sql /db
ADD table.customers /db
RUN apk add --update sqlite
#RUN mkdir /db
RUN sqlite3 microservices.db < /db/customers.sql

ENTRYPOINT ["sqlite3"]

FROM alpine:3.4
WORKDIR /db
ADD customers.sql /db
ADD customers.table /db
RUN apk add --update sqlite
RUN sqlite3 microservices.db < /db/customers.sql

ENTRYPOINT ["sqlite3"]

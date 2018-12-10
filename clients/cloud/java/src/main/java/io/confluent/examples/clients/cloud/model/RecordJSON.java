package io.confluent.examples.clients.cloud.model;

public class RecordJSON {

    Long count;

    public RecordJSON() {
    }

    public RecordJSON(Long count) {
        this.count = count;
    }

    public Long getCount() {
        return count;
    }

}

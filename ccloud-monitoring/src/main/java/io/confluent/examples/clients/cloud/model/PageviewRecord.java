package io.confluent.examples.clients.cloud.model;

public class PageviewRecord {

    Long viewtime;
    String userid;
    String pageid;

    public PageviewRecord() {
    }

    public PageviewRecord(Long viewtime, String userid, String pageid) {
        this.viewtime = viewtime;
        this.userid = userid;
        this.pageid = pageid;
    }

    public Long getViewtime() {
        return viewtime;
    }

    public String getUserid() {
        return userid;
    }

    public String getPageid() {
        return pageid;
    }

    public String toString() {
        return new com.google.gson.Gson().toJson(this);
    }

}

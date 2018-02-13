package com.routeanalyzer.dto;

import java.io.Serializable;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.routecommon.model.transit.Location;

public class LocationResponseDTO extends Location implements Serializable{
	
	public LocationResponseDTO (){};
	public LocationResponseDTO (double latitude, double longitude, int type) {
		this.setLatitude(latitude);
		this.setLongitude(longitude);
		this.type = type;
	}
	public LocationResponseDTO (double latitude, double longitude) {
		this.setLatitude(latitude);
		this.setLongitude(longitude);
	}
	public LocationResponseDTO (Location location, int type) {
		this.setLatitude(location.getLatitude());
		this.setLongitude(location.getLongitude());
		this.type = type;
	}
	public LocationResponseDTO (Location location) {
		this.setLatitude(location.getLatitude());
		this.setLongitude(location.getLongitude());
	}
	public int getType() {
		return type;
	}

	public void setType(int type) {
		this.type = type;
	}
	 /**展示类型
	  * 1原始点
	  * 2近似点
	  * 3未开始/预览点
	  * 4双向可达
	  * 5从目标出发可达（）
	  * 6到目标可达
	  * 7时间内不可达、
	  * 8无方案
	  * 9错误*/
	@JsonProperty("type")
	private int type;
	
	public boolean isFinish() {
		return finish;
	}
	public void setFinish(boolean finish) {
		this.finish = finish;
	}
	public int getFrom() {
		return from;
	}
	public void setFrom(int from) {
		this.from = from;
	}
	public int getTo() {
		return to;
	}
	public void setTo(int to) {
		this.to = to;
	}
	@JsonProperty("from")
	private int from;
	@JsonProperty("to")
	private int to;
	@JsonProperty("finish")
	private boolean finish;
}

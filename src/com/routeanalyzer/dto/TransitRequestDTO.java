package com.routeanalyzer.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.routecommon.model.transit.Location;

public class TransitRequestDTO {

	public int getETAToPos() {
		return ETAToPos;
	}

	public void setETAToPos(int eTAToPos) {
		ETAToPos = eTAToPos;
	}

	public int getETAfromPos() {
		return ETAfromPos;
	}

	public void setETAfromPos(int eTAfromPos) {
		ETAfromPos = eTAfromPos;
	}

	public Location getPosition() {
		return position;
	}

	public void setPosition(Location position) {
		this.position = position;
	}
	
	public double getBlockSizeFactor() {
		return blockSizeFactor;
	}

	public void setBlockSizeFactor(double blockSizeFactor) {
		this.blockSizeFactor = blockSizeFactor;
	}
	
	@JsonProperty("blockSizeFactor")
	private double blockSizeFactor;
	
	@JsonProperty("ETAto")
	private int ETAToPos;

	@JsonProperty("ETAfrom")
	private int ETAfromPos;

	@JsonProperty("position")
	private Location position;
}

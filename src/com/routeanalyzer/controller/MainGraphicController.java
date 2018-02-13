package com.routeanalyzer.controller;

import java.io.StringWriter;
import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.routeanalyzer.dto.LocationResponseDTO;
import com.routeanalyzer.dto.TransitRequestDTO;
import com.routeanalyzer.mq.MQProducer;
import com.routecommon.common.Constants;
import com.routecommon.dto.TransitResultCacheDTO;
import com.routecommon.model.transit.CityRange;
import com.routecommon.model.transit.Location;
import com.routecommon.model.transit.LocationCorrectionParam;
import com.routecommon.util.CommonUtil;
import com.routecommon.util.SerializerUtil;
import com.routecommon.util.transit.TransitUtil;

import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisPool;
@Controller
public class MainGraphicController {
	@Autowired
	private MQProducer mqProducer;
	
	/*@Autowired
	private MongoTemplate mongoTemplate;*/
	@Autowired
	private JedisPool jedisPool;//注入JedisPool
	
	
	private Jedis getJedis() {
		return jedisPool.getResource();
	}
	
	public void removeCache(String key) {
		Jedis jedis = getJedis();
		try{
			jedis.del(key.getBytes());
		} finally {
			jedis.close();
		}
	}
	
	public <T> String putCache(String key, T obj) {
		final byte[] bkey = key.getBytes();
		final byte[] bvalue = SerializerUtil.serializeObj(obj);
		Jedis jedis = getJedis();
		try{
			jedis.expire(bkey, 5000);
			return jedis.set(bkey, bvalue);
			
		} finally {
			jedis.close();
		}
	}

	//根据key取缓存数据
	public <T> T getCache(final String key) {
		byte[] result; 
		Jedis jedis =getJedis();
		try{
			result = jedis.get(key.getBytes());
		} finally {
			jedis.close();
		}
		return (T) SerializerUtil.deserializeObj(result);
	}
	
	public <T> T getListCache(String key, boolean fromR) {
		byte[] result; 
		Jedis jedis =getJedis();
		try{
			if(fromR)
				result = jedis.rpop(key.getBytes());
			else
				result = jedis.lpop(key.getBytes());
		} finally {
			jedis.close();
		}
		return (T) SerializerUtil.deserializeObj(result);
	}
	
	@ResponseBody
	@RequestMapping(value = "/commitTask", method = RequestMethod.POST,consumes = "application/json")
	public String commitTask(@RequestBody String request) {
		ObjectMapper mapper = new ObjectMapper();  
		TransitRequestDTO transitRequest;
		try {
			transitRequest = mapper.readValue(request, TransitRequestDTO.class);
		} catch (Exception e) {
			e.printStackTrace();
			return "{translationFailed}";
		}
		
		if(transitRequest.getBlockSizeFactor()<0.1) {
			transitRequest.setBlockSizeFactor(20.0);
		} else if(transitRequest.getBlockSizeFactor() < 2.0){
			transitRequest.setBlockSizeFactor(2.0);
		} else if(transitRequest.getBlockSizeFactor() > 20.0) {
			transitRequest.setBlockSizeFactor(20.0);
		}
		if(transitRequest.getPosition() != null) {
			if(transitRequest.getPosition().getLatitude()>0.0 &&transitRequest.getPosition().getLongitude()>0.0) {
				String taskCertificate = java.util.UUID.randomUUID().toString().substring(0,8);
				mqProducer.sendDataToQueue("huader.key", taskCertificate + request);
				return "{\"code\":200, \"certificate\":\"" + taskCertificate + "\"}";
			}
		}
		return "{\"code\":400}";
	}

	@ResponseBody
	@RequestMapping(value = "/getTaskResult", method = RequestMethod.POST,consumes = "application/json")
	public String getTaskResult(@RequestBody String ticket) {
		System.out.println("请求获取处理结果  "+ticket);
		List<LocationResponseDTO> resultList = new ArrayList<>();
		if(ticket != null) {
			boolean finish = false;
			final int maxCount = 100;
			int count = 0;
			int dropCount = 0;
			List<TransitResultCacheDTO> transitResultCacheList = new ArrayList<>();
			Integer fromPos = null;
			Integer toPos = null;
			try{
				fromPos = getCache(ticket + "FromPos");
				toPos = getCache(ticket + "ToPos");
			} catch (Exception e) {
				System.out.println("获取时间失败"+e.getMessage());;
			}
			if(fromPos != null && toPos != null) {
				while (count < maxCount) {
					TransitResultCacheDTO transitResultCache =null;
					try{
						transitResultCache = getListCache(ticket, false);
					} catch (Exception e) {
						System.out.println("获取队列失败"+e.getMessage());//e.printStackTrace();
					}
					if(transitResultCache == null)break;
					if(transitResultCache.isFinish()) {
						finish = true;
					} else if(transitResultCache.getFromLocation() != null 
							&& transitResultCache.getToLocation() != null 
							&& transitResultCache.getTimeFromPos()!=null 
							&& transitResultCache.getTimeToPos() != null){
						transitResultCacheList.add(transitResultCache);
						count++;
					} else {
						dropCount++;
					}
				}
				System.out.println(ticket +": 缓存获取次数  + " + count);
				if(dropCount > 0)
					System.out.println(ticket +": 丢弃缓存次数  + " + dropCount);
				for(TransitResultCacheDTO transitResultCache : transitResultCacheList) {
					LocationResponseDTO locationResponseDTO = new LocationResponseDTO (transitResultCache.getToLocation()); 
//					if(transitResponsePairModel.getFromTransitResponseModel().getMessage() == null || transitResponsePairModel.getToTransitResponseModel().getMessage() == null){
//						locationResponseDTO.setType(9);
//					} else {
					int fromDuration = transitResultCache.getTimeFromPos();
					int toDuration = transitResultCache.getTimeToPos();
					if(fromDuration == Integer.MAX_VALUE && toDuration == Integer.MAX_VALUE) {
						locationResponseDTO.setType(8);
					} else if(fromDuration <= fromPos) {
						if(toDuration <= toPos) {
							locationResponseDTO.setType(4);
						} else {
							locationResponseDTO.setType(5);
						}
					} else {
						if(toDuration <= toPos) {
							locationResponseDTO.setType(6);
						}
						else {
							locationResponseDTO.setType(7);
						}
					}
					resultList.add(locationResponseDTO);
				}
				if(finish){
					LocationResponseDTO finishedLocationResponseDTO = new LocationResponseDTO();
					finishedLocationResponseDTO.setFinish(true);
					resultList.add(finishedLocationResponseDTO);
					removeCache(ticket);
					removeCache(ticket + "FromPos");
					removeCache(ticket + "ToPos");
				}
			}
		}
		ObjectMapper mapper = new ObjectMapper();
		StringWriter w = new StringWriter();  
		//Convert between List and JSON    
		try {
			mapper.writeValue(w, resultList);
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "{}";
		}
		return w.toString();
	}
	@ResponseBody
	@RequestMapping(value = "/getTaskResult2", method = RequestMethod.POST,consumes = "application/json")
	public String getTaskResult2(@RequestBody String ticket) {
		System.out.println("请求获取处理结果  "+ticket);
		List<LocationResponseDTO> resultList = new ArrayList<>();
		if(ticket != null) {
			boolean finish = false;
			final int maxCount = 100;
			int count = 0;
			int dropCount = 0;
			List<TransitResultCacheDTO> transitResultCacheList = new ArrayList<>();
			Integer fromPos = null;
			Integer toPos = null;
			try{
				fromPos = getCache(ticket + "FromPos");
				toPos = getCache(ticket + "ToPos");
			} catch (Exception e) {
				System.out.println("获取时间失败"+e.getMessage());;
			}
			if(fromPos != null && toPos != null) {
				while (count < maxCount) {
					TransitResultCacheDTO transitResultCache =null;
					try{
						transitResultCache = getListCache(ticket, false);
					} catch (Exception e) {
						System.out.println("获取队列失败"+e.getMessage());//e.printStackTrace();
					}
					if(transitResultCache == null)break;
					if(transitResultCache.isFinish()) {
						finish = true;
					} else if(transitResultCache.getFromLocation() != null 
							&& transitResultCache.getToLocation() != null 
							&& transitResultCache.getTimeFromPos()!=null 
							&& transitResultCache.getTimeToPos() != null){
						transitResultCacheList.add(transitResultCache);
						count++;
					} else {
						dropCount++;
					}
				}
				System.out.println(ticket +": 缓存获取次数  + " + count);
				if(dropCount > 0)
					System.out.println(ticket +": 丢弃缓存次数  + " + dropCount);
				for(TransitResultCacheDTO transitResultCache : transitResultCacheList) {
					LocationResponseDTO locationResponseDTO = new LocationResponseDTO (transitResultCache.getToLocation()); 
//					if(transitResponsePairModel.getFromTransitResponseModel().getMessage() == null || transitResponsePairModel.getToTransitResponseModel().getMessage() == null){
//						locationResponseDTO.setType(9);
//					} else {
					int fromDuration = transitResultCache.getTimeFromPos();
					int toDuration = transitResultCache.getTimeToPos();
					locationResponseDTO.setFrom(fromDuration);
					locationResponseDTO.setTo(toDuration);
					resultList.add(locationResponseDTO);
				}
				if(finish){
					LocationResponseDTO finishedLocationResponseDTO = new LocationResponseDTO();
					finishedLocationResponseDTO.setFinish(true);
					resultList.add(finishedLocationResponseDTO);
					removeCache(ticket);
					removeCache(ticket + "FromPos");
					removeCache(ticket + "ToPos");
				}
			}
		}
		ObjectMapper mapper = new ObjectMapper();
		StringWriter w = new StringWriter();  
		//Convert between List and JSON    
		try {
			mapper.writeValue(w, resultList);
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "{}";
		}
		return w.toString();
	}
	@ResponseBody
	@RequestMapping(value = "/previewTask", method = RequestMethod.POST,consumes = "application/json")
	public String previewTask(@RequestBody String request) {//TransitRequestDTO request
		ObjectMapper mapper = new ObjectMapper();  
		
		TransitRequestDTO transitRequest;
		try {
			transitRequest = mapper.readValue(request, TransitRequestDTO.class);
		} catch (Exception e) {
			e.printStackTrace();
			return "{translationFailed}";
		}
		//request.setPosition(new Location(30.2574, 120.05311));
		CommonUtil.roundHalf(transitRequest.getPosition().getLatitude(),6);
		if(transitRequest.getBlockSizeFactor()<0.1) {
			transitRequest.setBlockSizeFactor(30.0);
		} else if(transitRequest.getBlockSizeFactor() < 2.5){
			transitRequest.setBlockSizeFactor(2.5);
		} else if(transitRequest.getBlockSizeFactor() > 80.0) {
			transitRequest.setBlockSizeFactor(80.0);
		}
		transitRequest.setBlockSizeFactor(CommonUtil.roundHalf(transitRequest.getBlockSizeFactor(), 1));
		
		LocationCorrectionParam locationCorrectionParam = new LocationCorrectionParam(transitRequest.getBlockSizeFactor());
		CityRange cityRange = TransitUtil.getNearestCityRange(transitRequest.getPosition());
		List<Location> allLocationList = TransitUtil.getDestinationLocationList(cityRange, locationCorrectionParam);
		Location oriApproxiLocation = TransitUtil.getNearestLocation(allLocationList, transitRequest.getPosition());
		//List<Location> mainLocationList = new ArrayList<>();
		List<LocationResponseDTO> resultList = new ArrayList<>();
		resultList.add(new LocationResponseDTO(transitRequest.getPosition(), 1));
		resultList.add(new LocationResponseDTO(oriApproxiLocation, 2));
		for(Location location : allLocationList) {
			resultList.add(new LocationResponseDTO(location, 3));
		}
		
		  
		StringWriter w = new StringWriter();  
		//Convert between List and JSON    
		try {
			mapper.writeValue(w, resultList);
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "{}";
		}
		return w.toString();
		
		//System.out.println(a.getInfo());
		/*Map<String,Object> msg = new HashMap<>();
		msg.put("data","hello,rabbmitmq!");*/
		//mqProducer.sendDataToQueue("huader.key",msg);
		
	}
	
	@RequestMapping(value = "/showCityMap", method = RequestMethod.GET)
	public String showCityMap(Model model) {
		CityRange cityRange = Constants.cityRangeList.get(0);
		model.addAttribute("cityCenterLongitude", (cityRange.getNorthWestCorner().getLongitude()+cityRange.getSouthEestCorner().getLongitude())/2.0);
		model.addAttribute("cityCenterLatitude",(cityRange.getNorthWestCorner().getLatitude()+cityRange.getSouthEestCorner().getLatitude())/2.0 );
		return "citymap";
	}
	
	@RequestMapping(value = "/showCityMap2", method = RequestMethod.GET)
	public String showCityMap2(Model model) {
		CityRange cityRange = Constants.cityRangeList.get(0);
		model.addAttribute("cityCenterLongitude", (cityRange.getNorthWestCorner().getLongitude()+cityRange.getSouthEestCorner().getLongitude())/2.0);
		model.addAttribute("cityCenterLatitude",(cityRange.getNorthWestCorner().getLatitude()+cityRange.getSouthEestCorner().getLatitude())/2.0 );
		return "citymap2";
	}
}

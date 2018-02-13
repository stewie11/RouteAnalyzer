<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE HTML>
<html>
<head>
	<title>交通分析工具</title>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
	<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no">
	<style type="text/css">
		html,body{
				margin:0;
				width:100%;
				height:100%;
				background:#303030;
		}
		#map{
				width:100%;
				height:93%;
				background:#303030;
		}
		
		#pannel1{height:7%;width:9%;background:#e05050;font-family:"微软雅黑";font-weight:bold;text-align:center;}
		#pannel2{height:7%;width:20%;font-family:"微软雅黑";font-weight:bold;}
		#pannel2_1_1{height:50%;width:80%;background:#0000ff;color:#B0B000;}
		#pannel2_1_2{height:50%;width:20%;background:#0000ff;font-family:"微软雅黑"; font-weight:bold; color:#B0B000;text-align:center;}
		#pannel2_2_1{height:50%;width:80%;background:#00ffff;}
		#pannel2_2_2{height:50%;width:20%;background:#00ffff;font-family:"微软雅黑"; font-weight:bold; color:#000000;text-align:center;}
		
		#changeETA{height:7%;width:4%;background:#ffff00;text-align:center; color:#B0B000;font-family:"微软雅黑";font-weight:bold;}
		#pannel3{height:7%;width:4%;background:#ffa000;font-family:"微软雅黑";font-weight:bold;text-align:center;}
		#pannel4{height:7%;width:8%;background:#00ff00;font-family:"微软雅黑";font-weight:bold;text-align:center;}
		#pannel5{height:7%;width:12%;background:#ff0000;font-family:"微软雅黑";font-weight:bold;text-align:center;}
		#pannel6{height:7%;width:5%;background:#9E9E9E;font-family:"微软雅黑";font-weight:bold;text-align:center;}
		#pannel7{height:7%;width:3%;background:#8000ff;font-family:"微软雅黑";font-weight:bold;text-align:center;}
		#pannel8{height:7%;width:13%;background:#000000;font-family:"微软雅黑";font-weight:bold;text-align:center;}
	
		#resultPannel{height:7%;width:17%;}
		#result{height:50%;font-family:"微软雅黑"; font-weight:bold; font-size:23px;text-align:center; color:#B0B000;float:none;}
		#clock{height:50%;font-family:"微软雅黑"; font-weight:bold; font-size:18px;text-align:left; color:#00ff00;float:none;}
		#resetButton{height:7%;width:5%;font-family:"微软雅黑"; font-weight:bold; font-size:23px;text-align:center; color:#B0B000;}

		div{
            float: left;
        }
	</style>
	
	<!-- <script type="text/javascript" src="http://code.jquery.com/jquery-1.9.1.min.js"></script> -->
	<!-- <script type="text/javascript" src="https://code.jquery.com/jquery-3.2.1.slim.min.js"></script> -->
	<%-- <script type="text/javascript" src="<c:out value="${pageContext.request.contextPath}" />/frontend/jquery-3.2.1.slim.min.js"></script> --%>
	<script src="https://cdn.bootcss.com/jquery/1.9.0/jquery.js"></script>
	<script type="text/javascript" src="http://api.map.baidu.com/api?v=2.0&ak=7c2FTzlrot1Q6PihLcjBjptXuaFnbvNQ"></script>
</head>

<body>
	<div id="map"></div>
	<div id="pannel1" style="color:#A0A0A0;">
		精确度<input type="tel" id="blockSize" size="20" value=5000.0 style="width:60px;" />（米）
	</div>
	<div id="pannel2">
		<div id="pannel2_1_1">
			从目标出发到达星星 期望时间<input type="tel" id="toStar" size="20" value=3600 style="width:16%; font-family:微软雅黑;"/>秒
		</div>
		<div id="pannel2_1_2" onclick=switchDisPlay(6);>
			
		</div>
		<div id="pannel2_2_1">
			从星星出发到达目标 期望时间<input type="tel" id="fromStar" size="20" value=3600 style="width:16%; font-family:微软雅黑;"/>秒
		</div>
		<div id="pannel2_2_2"onclick=switchDisPlay(5);>
			
		</div>
	</div>
	<div id="changeETA" onclick=changeETA();>
		改变期望
	</div>
	<div id="pannel3" onclick=switchDisPlay(1);>
		星星点
	</div>
	<div id="pannel4" onclick=switchDisPlay(4);>
		双向符合条件
	</div>
	<div id="pannel5" style="color:#C0C0C0;text-align:center;"onclick=switchDisPlay(7);>
		无法在期望时间内抵达或被抵达
	</div>
	<div id="pannel6" onclick=switchDisPlay(8);>
		无公交结果
	</div>
	<div id="pannel7" style="color:#A0A0A0;"onclick=switchDisPlay(9);>
		错误
	</div>
	<div id="pannel8" style="color:#A0A0A0;;"onclick=switchDisPlay(3);>
		等待计算结果或计算结果丢失
	</div>
	<div id="resultPannel">
		<div id="result"></div>
		<div id="clock"></div> 
	</div>
	<div id="resetButton" onclick=onClickReset();>重置</div>
	
	<script>
		Array.prototype.remove = function(index) {  
			//检查index位置是否有效  
			if(index >= 0 && index < this.length){  
				var part1 = this.slice(0, index + 1);  
				var part2 = this.slice(index + 1);  
				part1.pop();  
				return (part1.concat(part2));  
			}  
			return this;  
		};
		/**展示类型
		  * 1原始点
		  * 2近似点
		  * 3未开始/预览点
		  * 4双向可达
		  * 5从目标出发可达（）
		  * 6到目标可达
		  * 7时间内不可达
		  * 8无方案
		  * 9错误*/
		//1/2出发点 城市中心橙色
		options = [{},
			{//1原始点 近似点
				size: BMAP_POINT_SIZE_BIG,
				shape: BMAP_POINT_SHAPE_STAR,
				color: '#FF8000'
			},{},
			{//3未开始/预览点
				size: BMAP_POINT_SIZE_NORMAL,
				shape: BMAP_POINT_SHAPE_RHOMBUS,
				color: '#000000'
			},
			{
				//4完全符合点绿色
				size: BMAP_POINT_SIZE_NORMAL,
				shape: BMAP_POINT_SHAPE_RHOMBUS,
				color: '#00FF00'
			},
			{
				// 5从目标出发可达（）
				size: BMAP_POINT_SIZE_NORMAL,
				shape: BMAP_POINT_SHAPE_RHOMBUS,
				color: '#00FFFF'
			},
			{
				size: BMAP_POINT_SIZE_NORMAL,
				shape: BMAP_POINT_SHAPE_RHOMBUS,
				color: '#0000FF'
			},
			{
				size: BMAP_POINT_SIZE_NORMAL,
				shape: BMAP_POINT_SHAPE_RHOMBUS,
				color: '#FF0000'
			},
			{
				size: BMAP_POINT_SIZE_NORMAL,
				shape: BMAP_POINT_SHAPE_RHOMBUS,
				color: '#9E9E9E'
			},
			{
				size: BMAP_POINT_SIZE_NORMAL,
				shape: BMAP_POINT_SHAPE_RHOMBUS,
				color: '#8000FF'
			}
		]
	</script>

	<script>
		function isPC() {
		    var userAgentInfo = navigator.userAgent;
		    var Agents = ["Android", "iPhone",
		                "SymbianOS", "Windows Phone",
		                "iPad", "iPod"];
		    var flag = true;
		    for (var v = 0; v < Agents.length; v++) {
		        if (userAgentInfo.indexOf(Agents[v]) > 0) {
		            flag = false;
		            break;
		        }
		    }
		    return flag;
		}
		function switchDisPlay(i){
			//if(status == "idle") {
				pointDisplay[i] = !pointDisplay[i];
				
			//}
			if(pointDisplay[i]){
				showPoints(i);
			} else {
				hidePoints(i);
			}
		}
	
		function onClickReset(){
			if(status == "idle") {
				map.addEventListener("click", clickHandler);
			}
		}
		
		function initializationMap() {
			status = "idle";
			pointsCollection=[[],[],[],[],[],[],[],[],[],[],[],[],[]];
			pointDisplay = [true,true,true,true,true,true,true,true,true,true,true,true,true];
			document.getElementById('resetButton').style.backgroundColor='#00ff00';
			clock = document.getElementById("clock"); 
			map = new BMap.Map("map", {});// 创建Map实例
			map.enableScrollWheelZoom();//启用滚轮放大缩小
			cityCenterLng = ${cityCenterLongitude};
			cityCenterLat = ${cityCenterLatitude};
			map.centerAndZoom(new BMap.Point(cityCenterLng, cityCenterLat), 14);// 初始化地图,设置中心点坐标和地图级别120.219825, 30.2445
			/**展示类型
			  * 1原始点
			  * 2近似点
			  * 3未开始/预览点
			  * 4双向可达
			  * 5从目标出发可达（）
			  * 6到目标可达
			  * 7时间内不可达
			  * 8无方案
			  * 9错误*/
			points = [[],[],[],[],[],[],[],[],[],[],[],[],[],[]];
			taskUpdater = window.setInterval(function(){}, 10000);//使用字符串执行方法 
			cancelTimer(taskUpdater);
		}

		function isJSON(str) {
			if (typeof str == 'string') {
				try {
					var obj = JSON.parse(str);
					if(str.indexOf('{')>-1) {
						return true;
					}
				} catch(e) {
					return false;
				}
			}
			return false;
		}
		
		function cancelTimer(timer) {
			if(!(typeof(timer)==="undefined")&& timer != null)
				window.clearTimeout(timer);//去掉定时器 
		}
		
		function changeETA() {
			if(!(typeof(lastCommit)==="undefined") && lastCommit != null && toStar.value > -1 && fromStar.value > -1){
				lastCommit.ETAto = toStar.value;
				lastCommit.ETAfrom = fromStar.value;	
				for(var i = 4; i <= 8; ++i) {
					points[i] = [];
				}
				for(var i = 0; i < resultPoints.length; ++i) {
					var type = getPointType(resultPoints[i]);
					points[type].push(new BMap.Point(resultPoints[i].lng, resultPoints[i].lat));
				}
				updateAllPoints();
			}
		}
		
		function updateCollectionData(i){
			if(i == 1){
				pointsCollection[1] = new BMap.PointCollection(points[1], options[1]);
				pointsCollection[1].addEventListener('click', function (e) {
					cancelTimer(mapButtonDelayer);
					if(window.confirm('单击点的坐标为：' + e.point.lng + ',' + e.point.lat + '，重要点, 确定要布置任务吗？')){
						var pt = e.point;
						var jsonRequestBody = { 
							"blockSizeFactor": blockSize.value/100.0,
							"ETAto": toStar.value,
							"ETAfrom": fromStar.value,
							"position": {"lng":pt.lng ,"lat":pt.lat}
						};
						var jsonString = JSON.stringify(jsonRequestBody);
						lastCommit = {
							"certificate":"",
							"blockSizeFactor": 0, 
							"ETAto": 0, 
							"ETAfrom": 0,
							"position": {"lng":0.0 ,"lat":0.0}
						}
						lastCommit.blockSizeFactor = jsonRequestBody.blockSizeFactor;
						lastCommit.ETAto = jsonRequestBody.ETAto;
						lastCommit.ETAfrom = jsonRequestBody.ETAfrom;
						lastCommit.position.lng = jsonRequestBody.position.lng;
						lastCommit.position.lat = jsonRequestBody.position.lat;
						cancelTimer(taskUpdater);
						map.removeEventListener("click", clickHandler);
						commitTask(jsonString);
						taskUpdater = window.setInterval(function(){accessServiceByJson(jsonString, getTaskResult)}, 2000);//使用字符串执行方法 
					}
				});
				pannel3.innerHTML = '星星点</br>'+points[i].length;
			} else if(i == 7){
				pointsCollection[7] = new BMap.PointCollection(points[7], options[7]);
				pointsCollection[7].addEventListener('click', function (e) {
					cancelTimer(mapButtonDelayer);
					alert('单击点的坐标为：' + e.point.lng + ',' + e.point.lat + '，3000秒内不可达');
				});
				pannel5.innerHTML = '无法在期望时间内抵达或被抵达</br>'+points[i].length;
			} else if(i == 5){
				pointsCollection[5] = new BMap.PointCollection(points[5], options[5]);
				pointsCollection[5].addEventListener('click', function (e) {
					cancelTimer(mapButtonDelayer);
					alert('单击点的坐标为：' + e.point.lng + ',' + e.point.lat + '，3000秒内不可达');
				});
				pannel2_2_2.innerHTML = points[i].length;
			} else if(i == 6){
				pointsCollection[6] = new BMap.PointCollection(points[6], options[6]);
				pointsCollection[6].addEventListener('click', function (e) {
					cancelTimer(mapButtonDelayer);
					alert('单击点的坐标为：' + e.point.lng + ',' + e.point.lat + '，3000秒内不可达');
				});
				pannel2_1_2.innerHTML = points[i].length;
			} else if(i == 4){
				pointsCollection[4] = new BMap.PointCollection(points[4], options[4]);
				pointsCollection[4].addEventListener('click', function (e) {
					cancelTimer(mapButtonDelayer);
					alert('单击点的坐标为：' + e.point.lng + ',' + e.point.lat + '，3000秒内可达');
				});
				pannel4.innerHTML = '双向符合条件</br>'+points[i].length;
			} else if(i == 8){
				pointsCollection[8] = new BMap.PointCollection(points[8], options[8]);
				pointsCollection[8].addEventListener('click', function (e) {
					cancelTimer(mapButtonDelayer);
					alert('单击点的坐标为：' + e.point.lng + ',' + e.point.lat + '，无公交结果');
				});
				pannel6.innerHTML = '无公交结果</br>'+points[i].length;
			} else if(i == 9){
				pointsCollection[9] = new BMap.PointCollection(points[9], options[9]);
				pointsCollection[9].addEventListener('click', function (e) {
					cancelTimer(mapButtonDelayer);
					alert('单击点的坐标为：' + e.point.lng + ',' + e.point.lat + '，错误点');
				});
				pannel7.innerHTML = '错误</br>'+points[i].length;
			} else if(i == 3){
				pointsCollection[3] = new BMap.PointCollection(points[3], options[3]);
				pointsCollection[3].addEventListener('click', function (e) {
					cancelTimer(mapButtonDelayer);
					alert('单击点的坐标为：' + e.point.lng + ',' + e.point.lat + '，正在等待返回结果');
				});
				pannel8.innerHTML = '等待计算结果或计算结果丢失</br>'+points[i].length;
			}
		}
		
		function hidePoints(i) {
			if(!(typeof(pointsCollection[i])==="undefined") && pointsCollection[i] != null)
				map.removeOverlay(pointsCollection[i]);
		}
		
		function updateAllPoints() {
			if(!(typeof(pointsCollection)==="undefined") && !(typeof(pointsCollection[1])==="undefined") && pointsCollection[1] != null) {
				hideAllPoints();
			}
			showAllPoints();
		}
		
		function showPoints(i) {
			updateCollectionData(i);
			if(!(typeof(pointsCollection[i])==="undefined") && pointsCollection[i] != null && pointDisplay[i])
				map.addOverlay(pointsCollection[i]);
		}
		
		function showAllPoints() {
			for(var i = 0; i <= 9; i++) {
				showPoints(i)
			}
		}
		
		function hideAllPoints() {
			for(var i = 0; i <= 9; i++) {
				hidePoints(i);
			}
		}
		
		function accessServiceByJson(jsonString, service) {
			service(jsonString);
		}
		
		function updateClock(){
			var nowTime = new Date().getTime();
			var timePassed = parseInt((nowTime - taskCommitTime)/1000);
			var processedNum = points[0].length - points[1].length - points[3].length;
			var processedSpeed = processedNum / timePassed;
			clock.innerHTML='耗时:  ' + parseInt((nowTime - taskCommitTime)/1000) + '秒   分析速度:  '  + processedSpeed.toFixed(1)+' 点每秒';
		}
		
		function commitTask(requestBody) {
			$.ajax({
				url:'commitTask',
				method:'POST',
				dataType:'json',
				contentType:'application/json',
				data:requestBody,
				success: function (result) {
					if(result != null && result.code == 200 && result.certificate != null) {
						taskCommitTime = new Date().getTime();
						clock.innerHTML='';
						clockTimer = window.setInterval(function(){updateClock()}, 1000);
						status = "run";
						document.getElementById('resetButton').style.backgroundColor='#004000';
						certificateCode = result.certificate;
						alert('请求成功凭证号为' + certificateCode);
						lastCommit.certificate = certificateCode;
					} else {
						alert('请求失败');
					}
				}
			});
		}

		function getTaskResult(requestBody) {
			$.ajax({
				url:'getTaskResult2',
				method:'POST',
				dataType:'json',
				contentType:'application/json',
				data:lastCommit.certificate,
				success: function (result) {
					var finished = 0;
					for(var i = 0; i < result.length; i++) {
						resultPoints.push(result[i]);
						var j = 0;
						for(; j < points[3].length; j++){
							if(points[3][j].lat == result[i].lat &&  points[3][j].lng == result[i].lng)
								break;
						}
						//console.log(result[i]);
						if(result[i].finish) {
							finished = 1;
							cancelTimer(taskUpdater);
							continue;
						} else if(j < points[3].length) {
							points[3] = points[3].remove(j);
							//console.log('删掉', result[i]);
							console.log('还剩',points[3].length);
						}
						else{
							console.log('这个点删不掉', result[i]);
						/* 	for(var k = 0 ; k < points[3].length; k++){
								console.log(points[3][k])
							} */
							//errorPoints.push(new BMap.Point(result[i].lng, result[i].lat));
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
						
						var type = getPointType(result[i]);
						points[type].push(new BMap.Point(result[i].lng, result[i].lat));
					}
					updateAllPoints();
					if(finished == 1){
						document.getElementById('result').innerHTML = '完成：' + (points[0].length - points[1].length - points[3].length)+ '/' + (points[0].length - 2);
						cancelTimer(clockTimer);
						alert('搞定了');
						status = "idle";
						document.getElementById('resetButton').style.backgroundColor='#00ff00';
					} else {
						document.getElementById('result').innerHTML = '处理中：' + (points[0].length - points[1].length - points[3].length)+ '/' + (points[0].length - 2);
					}
				}
			});
		}
		
		function getPointType(targetResult) {
			var type;
			if(targetResult.from == 0x7fffffff && targetResult.to == 0x7fffffff) {
				type = 8; 
			} else if(targetResult.from <= lastCommit.ETAfrom) {
				if(targetResult.to <= lastCommit.ETAto) {
					type = 4;
				} else {
					type = 5;
				}
			} else {
				if(targetResult.to <= lastCommit.ETAto) {
					type = 6;
				}
				else {
					type = 7;
				}
			}
			return type;
		}
		
		function previewTask(requestBody) {
			$.ajax({
				url:'previewTask',
				method:'POST',
				dataType:'json',
				contentType:'application/json',
				data:requestBody,
				success: function (result) {
					/**展示类型
					  * 1原始点
					  * 2近似点
					  * 3未开始/预览点
					  * 4双向可达
					  * 5从目标出发可达（）
					  * 6到目标可达
					  * 7时间内不可达
					  * 8无方案
					  * 9错误*/
					
					points = [[],[],[],[],[],[],[],[],[],[],[],[],[],[]];
					resultPoints = [];
					pointDisplay = [true, true, true, true, true, true, true, true, true, true, true, true, true];
					for(var i = 0; i < result.length; i++) {
						points[0].push([result[i].lng, result[i].lat]);
						 
						if(result[i].type == 1 || result[i].type == 2){
							points[1].push(new BMap.Point(result[i].lng, result[i].lat));
						} else {
							points[result[i].type].push(new BMap.Point(result[i].lng, result[i].lat));
						}
					}
					updateAllPoints();
					document.getElementById('result').innerHTML = '待处理点数：' + (points[0].length - 2);
				}
			});
		}
		
		clickHandler = function(e){
			//点击地图，获取到对应的point, 由point的lng、lat属性获取对应的经度纬度   
			var pt = e.point;
			var jsonRequestBody = {
				"blockSizeFactor": blockSize.value/100.0,
				"ETAto": toStar.value,
				"ETAfrom": fromStar.value,
				"position": {"lng":pt.lng,"lat":pt.lat}
			};
			var jsonString = JSON.stringify(jsonRequestBody);
			mapButtonDelayer = window.setTimeout(function(){accessServiceByJson(jsonString, previewTask)}, 40);//使用字符串执行方法	
		}
	</script>

	<script>
		if(!isPC()) {
		/* 	#pannel1{height:7%;width:10%;background:#e05050;font-family:"微软雅黑";font-weight:bold;text-align:center;}
			#pannel2{height:7%;width:20%;font-family:"微软雅黑";font-weight:bold;}
			#pannel2_1_1{height:50%;width:75%;background:#0000ff;color:#B0B000;}
			#pannel2_1_2{height:50%;width:25%;background:#0000ff;font-family:"微软雅黑"; font-weight:bold; color:#B0B000;text-align:center;}
			#pannel2_2_1{height:50%;width:75%;background:#00ffff;}
			#pannel2_2_2{height:50%;width:25%;background:#00ffff;font-family:"微软雅黑"; font-weight:bold; color:#000000;text-align:center;}
			
			#pannel3{height:7%;width:4%;background:#ffa000;font-family:"微软雅黑";font-weight:bold;text-align:center;}
			#pannel4{height:7%;width:8%;background:#00ff00;font-family:"微软雅黑";font-weight:bold;text-align:center;}
			#pannel5{height:7%;width:12%;background:#ff0000;font-family:"微软雅黑";font-weight:bold;text-align:center;}
			#pannel6{height:7%;width:7%;background:#9E9E9E;font-family:"微软雅黑";font-weight:bold;text-align:center;}
			#pannel7{height:7%;width:3%;background:#8000ff;font-family:"微软雅黑";font-weight:bold;text-align:center;}
			#pannel8{height:7%;width:13%;background:#000000;font-family:"微软雅黑";font-weight:bold;text-align:center;}
		
			#resultPannel{height:7%;width:18%;}
			#result{height:50%;font-family:"微软雅黑"; font-weight:bold; font-size:23px;text-align:center; color:#B0B000;float:none;}
			#clock{height:50%;font-family:"微软雅黑"; font-weight:bold; font-size:18px;text-align:left; color:#00ff00;float:none;}
			#resetButton{height:7%;width:5%;font-family:"微软雅黑"; font-weight:bold; font-si */
			document.getElementById("map").style.height='70%';
			document.getElementById("pannel1").style.height='30%';
			document.getElementById("pannel2").style.height='30%';
			document.getElementById("pannel3").style.height='30%';
			document.getElementById("pannel4").style.height='30%';
			document.getElementById("pannel5").style.height='30%';
			document.getElementById("pannel6").style.height='30%';
			document.getElementById("pannel7").style.height='30%';
			document.getElementById("pannel8").style.height='30%';
			document.getElementById("resultPannel").style.height='30%';
			document.getElementById("resetButton").style.height='30%';
			
			pannel2_1_1.innerHTML = '到星星秒<input type="tel" id="toStar" size="20" value=3600 style="width:13%; font-family:微软雅黑;"/>';
			pannel2_2_1.innerHTML = '到目标秒<input type="tel" id="fromStar" size="20" value=3600 style="width:13%; font-family:微软雅黑;"/>';
		
		}
		initializationMap();
		if(document.createElement('canvas').getContext) {
			//showAllPoints();
			var jsonRequestBody = { 
				"blockSizeFactor":blockSize.value/100.0, 
				"ETAto":toStar.value, 
				"ETAfrom":fromStar.value,
				"position":{"lng":cityCenterLng,"lat":cityCenterLat}
			}; 
			var jsonString = JSON.stringify(jsonRequestBody);
			var startTimer = window.setTimeout(function(){previewTask(jsonString)}, 800); //使用字符串执行方法
			map.addEventListener("click", clickHandler);
			//map.removeEventListener("click", clickHandler);
		} else {
			alert('请在chrome、safari、IE8+以上浏览器查看本示例');
		}
	</script>
</body>
</html>


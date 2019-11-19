<?php
	$jsonObj = "";
	if (($_GET["place_id"] == "") && ($_GET["next_page_token"] == "") && ($_GET["yelp"] == "")){
		
		$latlon = $_GET['latlon'];
		$distance = $_GET['distance'];
		$category = $_GET['category'];
		$keyword = $_GET['keyword'];
		
		$url = "";
		if($category == "default"){
			$url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=".$latlon."&radius=".$distance."&keyword=".$keyword."&key=Google key goes here!";
		}
		else{
			$url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=".$latlon."&radius=".$distance."&type=".$category."&keyword=".$keyword."&key=Google key goes here!";
		}
		$json = file_get_contents($url);
	}else if (($_GET["place_id"] != "") && ($_GET["next_page_token"] == "") && ($_GET["yelp"] == "")){
		$url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=".$_GET["place_id"]."&key=Google key goes here!";
		$json = file_get_contents($url);
	}else if (($_GET["place_id"] == "") && ($_GET["next_page_token"] != "") && ($_GET["yelp"] == "")){
		$url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?pagetoken=".$_GET["next_page_token"]."&key=Google key goes here!";
		$json = file_get_contents($url);
	}else if (($_GET["place_id"] == "") && ($_GET["next_page_token"] == "") && ($_GET["yelp"] != "")){
		if ($_GET["yelp"] == "businesses"){
			$lat = $_GET['lat'];
			$lon = $_GET['lon'];
			$term = $_GET['term'];
			$url = "https://api.yelp.com/v3/businesses/search?"."latitude=".$lat."&longitude=".$lon."&term=".$term;

			$opts = [
	    		"http" => [
	        		"method" => "GET",
	        		"header" => "Authorization: Bearer Yelp key goes here!"
	    		]
			];

			$context = stream_context_create($opts);

			$json = file_get_contents($url, false, $context);
		}else{
			
			$id = $_GET['id'];
			$url = "https://api.yelp.com/v3/businesses/".$id."/reviews";

			$opts = [
	    		"http" => [
	        		"method" => "GET",
	        		"header" => "Authorization: Bearer Yelp key goes here!"
	    		]
			];

			$context = stream_context_create($opts);

			$json = file_get_contents($url, false, $context);
		}
	}
	
	echo $json;
?>

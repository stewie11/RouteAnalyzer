package com.routeanalyzer.cache;

public interface Cache {
	<T> String putCache(String key, T obj);
	<T> T getCache(String key);
}
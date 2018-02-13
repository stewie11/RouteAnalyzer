package com.routeanalyzer.mq.impl;

import org.springframework.amqp.core.AmqpTemplate;
import org.springframework.amqp.core.Message;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.routeanalyzer.mq.MQProducer;

@Service
public class MQProducerImpl implements MQProducer {
    @Autowired
    private AmqpTemplate amqpTemplate;

    @Override
    public void sendDataToQueue(String queueKey, Object object) {
        try {
            amqpTemplate.convertAndSend(queueKey, object);
        } catch (Exception e) {
        	System.out.println("sendMessageFailed:  " + queueKey + " " + object.toString());
        	System.out.println(e.getMessage());
        }
    }
}
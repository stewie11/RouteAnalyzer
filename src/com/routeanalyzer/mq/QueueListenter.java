package com.routeanalyzer.mq;

import org.springframework.amqp.core.Message;
import org.springframework.amqp.core.MessageListener;
import org.springframework.stereotype.Component;

@Component("queueListenter")
public class QueueListenter implements MessageListener {

    @Override
    public void onMessage(Message msg) {
        try{
            System.out.println(msg.toString());
        }catch(Exception e){
            e.printStackTrace();
        }
    }

}
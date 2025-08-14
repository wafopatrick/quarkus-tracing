package dev.playground.payment;

import org.eclipse.microprofile.reactive.messaging.*;

import jakarta.enterprise.context.ApplicationScoped;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.CompletionStage;

@ApplicationScoped
public class PaymentProcessor {

    private static final Logger LOGGER = LoggerFactory.getLogger(PaymentProcessor.class);

    /**
     * Consume the message from the "orders-in" channel.
     * Messages come from the broker.
     **/
    @Incoming("orders-in")
    public CompletionStage<Void> handleOrderMessage(Message<Order> message) {
        LOGGER.info("Received order message: {}", message);
        return message.ack();
    }

}

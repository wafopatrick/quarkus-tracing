package dev.playground.order;

import io.quarkus.test.common.QuarkusTestResourceLifecycleManager;
import io.smallrye.reactive.messaging.memory.InMemoryConnector;

import java.util.HashMap;
import java.util.Map;

public class InMemoryConnectorLifecycleManager implements QuarkusTestResourceLifecycleManager {

    @Override
    public Map<String, String> start() {
        Map<String, String> props = InMemoryConnector.switchOutgoingChannelsToInMemory("orders-out");
        return new HashMap<>(props);
    }

    @Override
    public void stop() {
       InMemoryConnector.clear();
    }
}

package dev.playground.order;

import io.quarkus.test.Mock;
import io.quarkus.test.common.QuarkusTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.smallrye.mutiny.Uni;
import io.smallrye.reactive.messaging.memory.InMemoryConnector;
import io.smallrye.reactive.messaging.memory.InMemorySink;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.spi.Connector;
import org.eclipse.microprofile.rest.client.inject.RestClient;
import org.junit.jupiter.api.Test;
import io.smallrye.reactive.messaging.kafka.Record;


import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import static io.restassured.RestAssured.given;
import static org.awaitility.Awaitility.await;
import static org.hamcrest.CoreMatchers.is;
import static org.junit.jupiter.api.Assertions.assertEquals;

@QuarkusTest
@QuarkusTestResource(InMemoryConnectorLifecycleManager.class)
class OrderResourceTest {

    @Inject
    @Connector("smallrye-in-memory")
    InMemoryConnector inMemoryConnector;

    @Inject
    @RestClient
    InventoryClient inventoryClient;

    @Test
    void testCreateAndGetOrderWithSufficientStock() {
        // set up the mock inventory client with insufficient stock
        ((MockInventoryClient)inventoryClient).setStockLevel("test-sku", 10);

        // The order to be created
        Order order = new Order();
        order.sku = "test-sku";
        order.quantity = 5;

        String orderId = given()
                .contentType("application/json")
                .body(order)
                .when().post("/orders")
                .then()
                .statusCode(200)
                .extract().path("id");

        // Ruft die Bestellung ab
        given()
                .when().get("/orders/" + orderId)
                .then()
                .statusCode(200)
                .body("id", is(orderId));

        // Verify the message sent to orders-out via the emitter
        InMemorySink<Record<String, Order>> sink = inMemoryConnector.sink("orders-out");
        await().untilAsserted(() -> assertEquals(1, sink.received().size(), "One message should be sent"));  // Wait for a message
        Record<String, Order> sentRecord = sink.received().getFirst().getPayload();

        assertEquals("test-sku", sentRecord.value().sku, "SKU should match");
        assertEquals(5, sentRecord.value().quantity, "Quantity should match");
        assertEquals("PENDING", sentRecord.value().status, "Status should be PENDING");
    }

    @Test
    void testCreateOrderWithInsufficientStock() {
        // set up the mock inventory client with insufficient stock
        ((MockInventoryClient)inventoryClient).setStockLevel("test-sku", 2);

        // The order to be created
        Order order = new Order();
        order.sku = "test-sku";
        order.quantity = 5;

        given()
                .contentType("application/json")
                .body(order)
                .when().post("/orders")
                .then()
                .statusCode(200)
                .body("status", is("REJECTED_NO_STOCK"));

        // Verify the message sent to orders-out via the emitter
        InMemorySink<Record<String, Order>> sink = inMemoryConnector.sink("orders-out");
        await().untilAsserted(() -> assertEquals(0, sink.received().size(), "One message should be sent"));  // Wait for a message
    }

    @Mock
    @ApplicationScoped
    @RestClient
    public static class MockInventoryClient implements InventoryClient {
        private final Map<String, Integer> stockLevels = new ConcurrentHashMap<>();

        public void setStockLevel(String sku, int available) {
            stockLevels.put(sku, available);
        }

        @Override
        public Uni<Stock> check(String sku) {
            Stock stock = new Stock(sku, stockLevels.getOrDefault(sku, 10));
            return Uni.createFrom().item(stock);
        }
    }

}
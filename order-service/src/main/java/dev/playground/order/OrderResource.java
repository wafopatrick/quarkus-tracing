package dev.playground.order;

import io.smallrye.mutiny.Uni;
import io.smallrye.reactive.messaging.kafka.Record;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.eclipse.microprofile.rest.client.inject.RestClient;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Path("/orders")
@ApplicationScoped
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class OrderResource {

    private final Map<String, Order> orders = new ConcurrentHashMap<>();

    @Inject
    @Channel("orders-out")
    Emitter<Record<String, Order>> ordersOut;

    @Inject
    @RestClient
    InventoryClient inventoryClient;

    @POST
    public Uni<Order> create(Order order) {
        order.id = UUID.randomUUID().toString();
        order.status = "PENDING";

        return inventoryClient.check(order.sku)
            .onItem().transform(stock -> {
                if (stock == null || stock.available() < order.quantity) {
                    order.status = "REJECTED_NO_STOCK";
                } else {
                    ordersOut.send(Record.of(order.id, order));
                }
                orders.put(order.id, order);
                return order;
            });
    }

    @GET
    @Path("/{id}")
    public Order get(@PathParam("id") String id) {
        return orders.get(id);
    }
}


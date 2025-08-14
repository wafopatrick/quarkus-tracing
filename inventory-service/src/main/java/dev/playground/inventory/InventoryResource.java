package dev.playground.inventory;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Path("/inventory")
@ApplicationScoped
@Produces(MediaType.APPLICATION_JSON)
public class InventoryResource {

    private final Map<String, Integer> skuToQty = new ConcurrentHashMap<>(Map.of(
            "ABC-1", 100,
            "XYZ-9", 0,
            "FOO-7", 50
    ));

    @GET
    @Path("/{sku}")
    public Stock get(@PathParam("sku") String sku) {
        var qty = skuToQty.getOrDefault(sku, 0);
        var stock = new Stock();
        stock.sku = sku;
        stock.available = qty;
        return stock;
    }

    public static class Stock {
        public String sku;
        public int available;
    }
}

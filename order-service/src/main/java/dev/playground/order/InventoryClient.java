package dev.playground.order;

import io.smallrye.mutiny.Uni;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

@Path("/inventory")
@RegisterRestClient(configKey = "inventory")
public interface InventoryClient {

    @GET
    @Path("/{sku}")
    @Produces(MediaType.APPLICATION_JSON)
    Uni<Stock> check(@PathParam("sku") String sku);
}
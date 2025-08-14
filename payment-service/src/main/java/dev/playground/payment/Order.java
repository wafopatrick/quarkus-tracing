package dev.playground.payment;

public record Order(String id, String sku, int quantity, String status) {}

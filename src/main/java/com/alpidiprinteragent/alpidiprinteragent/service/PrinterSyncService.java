package com.alpidiprinteragent.alpidiprinteragent.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class PrinterSyncService {

  @Value("${backend.base-url}")
  private String backendBaseUrl;

  private final ConfigService configService;
  private final RestTemplate restTemplate;
  private final ObjectMapper objectMapper = new ObjectMapper();

  public PrinterSyncService(ConfigService configService) {
    this.configService = configService;
    this.restTemplate = new RestTemplate();
  }

  @Scheduled(cron = "0 0 7 * * ?", zone = "America/New_York")
  public void syncActivePrinter() {
    String productionPartnerUserId = configService.getProductionPartnerUserId();

    try {
      String jsonResponse =
          restTemplate.getForObject(
              backendBaseUrl + "/api/public/printer/" + productionPartnerUserId + "/default-active",
              String.class);

      if (jsonResponse != null && !jsonResponse.isEmpty()) {
        JsonNode root = objectMapper.readTree(jsonResponse);
        int statusCode = root.path("statuscode").asInt();
        boolean status = root.path("status").asBoolean();

        if (statusCode == 200 && status) {
          String printerName = root.path("data").asText();

          String localPrinter = configService.getActivePrinter();

          if (!printerName.equals(localPrinter)) {
            configService.setActivePrinter(printerName, productionPartnerUserId);
            System.out.println("[SYNC] Local active printer updated to: " + printerName);
          }
        } else {
          System.err.println(
              "[SYNC] Unexpected response status: " + statusCode + ", status: " + status);
        }
      }

    } catch (Exception e) {
      System.err.println("[SYNC ERROR] " + e.getMessage());
    }
  }
}

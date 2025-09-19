package com.alpidiprinteragent.alpidiprinteragent.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.io.IOException;
import java.nio.file.*;
import org.springframework.stereotype.Service;

@Service
public class ConfigService {
  private static final Path CONFIG_FILE = Paths.get("printer-config.json");
  private final ObjectMapper objectMapper = new ObjectMapper();

  public String getActivePrinter() {
    try {
      if (Files.exists(CONFIG_FILE)) {
        String jsonContent = Files.readString(CONFIG_FILE);
        JsonNode config = objectMapper.readTree(jsonContent);
        return config.path("activePrinter").asText(null);
      }
    } catch (IOException e) {
      e.printStackTrace();
    }
    return null;
  }

  public String getProductionPartnerUserId() {
    try {
      if (Files.exists(CONFIG_FILE)) {
        String jsonContent = Files.readString(CONFIG_FILE);
        JsonNode config = objectMapper.readTree(jsonContent);
        return config.path("productionPartnerUserId").asText(null);
      }
    } catch (IOException e) {
      e.printStackTrace();
    }
    return null;
  }

  public void setActivePrinter(String printerName, String productionPartnerUserId) {
    try {
      ObjectNode config = objectMapper.createObjectNode();

      // Read current configuration (if any)
      if (Files.exists(CONFIG_FILE)) {
        try {
          String existingContent = Files.readString(CONFIG_FILE);
          config = (ObjectNode) objectMapper.readTree(existingContent);
        } catch (IOException e) {
          // Create a new config if the existing file is corrupt
          config = objectMapper.createObjectNode();
        }
      }

      // Update active printer
      config.put("activePrinter", printerName);
      config.put("productionPartnerUserId", productionPartnerUserId);
      config.put("lastUpdated", System.currentTimeMillis());

      // Write JSON file
      String jsonString = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(config);
      Files.writeString(
          CONFIG_FILE, jsonString, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);

    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  // Additional configuration methods
  public void setPrintSettings(String key, Object value) {
    try {
      ObjectNode config = getOrCreateConfig();

      // Create or get a printSettings object
      ObjectNode printSettings;
      if (config.has("printSettings") && config.get("printSettings").isObject()) {
        printSettings = (ObjectNode) config.get("printSettings");
      } else {
        printSettings = objectMapper.createObjectNode();
        config.set("printSettings", printSettings);
      }

      // Add the value
      if (value instanceof String) {
        printSettings.put(key, (String) value);
      } else if (value instanceof Integer) {
        printSettings.put(key, (Integer) value);
      } else if (value instanceof Boolean) {
        printSettings.put(key, (Boolean) value);
      } else {
        printSettings.put(key, value.toString());
      }

      config.put("lastUpdated", System.currentTimeMillis());

      // Save the file
      saveConfig(config);

    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  public String getPrintSetting(String key, String defaultValue) {
    try {
      if (Files.exists(CONFIG_FILE)) {
        String jsonContent = Files.readString(CONFIG_FILE);
        JsonNode config = objectMapper.readTree(jsonContent);
        JsonNode printSettings = config.path("printSettings");
        return printSettings.path(key).asText(defaultValue);
      }
    } catch (IOException e) {
      e.printStackTrace();
    }
    return defaultValue;
  }

  public JsonNode getAllConfig() {
    try {
      if (Files.exists(CONFIG_FILE)) {
        String jsonContent = Files.readString(CONFIG_FILE);
        return objectMapper.readTree(jsonContent);
      }
    } catch (IOException e) {
      e.printStackTrace();
    }
    return objectMapper.createObjectNode();
  }

  // Helper methods
  private ObjectNode getOrCreateConfig() throws IOException {
    if (Files.exists(CONFIG_FILE)) {
      try {
        String existingContent = Files.readString(CONFIG_FILE);
        return (ObjectNode) objectMapper.readTree(existingContent);
      } catch (IOException e) {
        // If the file is corrupt, create a new one
      }
    }
    return objectMapper.createObjectNode();
  }

  private void saveConfig(ObjectNode config) throws IOException {
    String jsonString = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(config);
    Files.writeString(
        CONFIG_FILE, jsonString, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
  }

  // Reset configuration file
  public void resetConfig() {
    try {
      Files.deleteIfExists(CONFIG_FILE);
    } catch (IOException e) {
      e.printStackTrace();
    }
  }
}

package com.alpidiprinteragent.alpidiprinteragent.controller;

import com.alpidiprinteragent.alpidiprinteragent.service.ConfigService;
import com.alpidiprinteragent.alpidiprinteragent.service.PrinterService;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@CrossOrigin(
    origins = {
      "http://localhost:4200",
      "https://alpidi.com",
      "https://app.alpidi.com",
      "https://test.alpidi.com",
      "https://stage.alpidi.com"
    })
@RestController
public class PrinterController {
  @Autowired private PrinterService printerService;

  @Autowired private ConfigService configService;

  @GetMapping("/i-am-here")
  public ResponseEntity<Map<String, Object>> getIAmHere() {
    Map<String, Object> response = new HashMap<>();
    response.put("status", true);
    response.put("message", "The agent already exist");
    response.put("timestamp", System.currentTimeMillis());
    return ResponseEntity.ok(response);
  }

  @GetMapping("/printers")
  public List<String> getPrinters() {
    return printerService.getPrinters();
  }

  @GetMapping("/printers-details")
  public List<PrinterService.PrinterDetails> getPrintersWithDetails() {
    return printerService.getPrintersDetails();
  }

  @PostMapping("/printers/active")
  public ResponseEntity<Map<String, Object>> setActivePrinter(
      @RequestBody Map<String, String> body) {
    Map<String, Object> response = new HashMap<>();

    try {
      String printerName = body.get("printerName");
      String productionPartnerUserId = body.get("productionPartnerUserId");

      if (printerName == null || printerName.trim().isEmpty()) {
        response.put("status", false);
        response.put("message", "Printer name cannot be empty");
        response.put("errorCode", "PRINTER_NAME_REQUIRED");
        return ResponseEntity.badRequest().body(response);
      }

      configService.setActivePrinter(printerName, productionPartnerUserId);

      response.put("status", true);
      response.put("message", "Active printer successfully set to: " + printerName);
      response.put("activePrinter", printerName);
      response.put("timestamp", System.currentTimeMillis());

      return ResponseEntity.ok(response);

    } catch (Exception e) {
      response.put("status", false);
      response.put("message", "Error occurred while setting printer: " + e.getMessage());
      response.put("errorCode", "PRINTER_SET_ERROR");
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
  }

  @PostMapping("/print")
  public ResponseEntity<Map<String, Object>> print(@RequestBody Map<String, String> body) {
    Map<String, Object> response = new HashMap<>();
    Map<String, Object> data = new HashMap<>();

    try {
      String fileName = body.get("fileName");
      String pdfData = body.get("pdfData");

      // Input validation
      if (pdfData == null || pdfData.trim().isEmpty()) {
        response.put("status", false);
        response.put("statuscode", 404);
        response.put("message", "PDF data cannot be null or empty");
        response.put("data", "PDF_DATA_REQUIRED");
        return ResponseEntity.badRequest().body(response);
      }

      // Check if active printer is configured
      String printer = configService.getActivePrinter();
      if (printer == null || printer.trim().isEmpty()) {
        response.put("status", false);
        response.put("statuscode", 404);
        response.put("message", "No active printer configured. Please select a printer first.");
        response.put("data", "NO_ACTIVE_PRINTER");
        return ResponseEntity.badRequest().body(response);
      }

      // Decode Base64 PDF data
      byte[] pdfBytes;
      try {
        pdfBytes = Base64.getDecoder().decode(pdfData);
      } catch (IllegalArgumentException e) {
        response.put("status", false);
        response.put("statuscode", 404);
        response.put("message", "Invalid PDF data format");
        response.put("data", e.getMessage());
        return ResponseEntity.badRequest().body(response);
      }

      // Perform print operation
      printerService.printPdf(printer, pdfBytes);
      data.put("printerName", printer);
      data.put("fileName", fileName != null ? fileName : "document.pdf");
      data.put("timestamp", System.currentTimeMillis());
      data.put("documentSize", pdfBytes.length);

      // Success response
      response.put("status", true);
      response.put("statuscode", 200);
      response.put("message", "Print job completed successfully");
      response.put("data", data);

      return ResponseEntity.ok(response);

    } catch (Exception e) {
      data.put("errorCode", "PRINT_ERROR");
      data.put("timestamp", System.currentTimeMillis());

      response.put("status", false);
      response.put("statuscode", 500);
      response.put("message", "Print operation failed: " + e.getMessage());
      response.put("data", data);

      // Log the error for debugging
      e.printStackTrace();

      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
  }

  @GetMapping("/config")
  public JsonNode getConfig() {
    return configService.getAllConfig();
  }

  @PostMapping("/config/print-settings")
  public ResponseEntity<Map<String, Object>> updatePrintSettings(
      @RequestBody Map<String, Object> settings) {
    Map<String, Object> response = new HashMap<>();

    try {
      settings.forEach(configService::setPrintSettings);

      response.put("status", true);
      response.put("statuscode", 201);
      response.put("message", "Print settings updated successfully");
      response.put("updatedSettings", settings);
      response.put("timestamp", System.currentTimeMillis());

      return ResponseEntity.ok(response);

    } catch (Exception e) {
      response.put("status", false);
      response.put("statuscode", 500);
      response.put("message", "Error occurred while updating settings: " + e.getMessage());
      response.put("errorCode", "SETTINGS_UPDATE_ERROR");

      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
  }

  @PostMapping("/config/reset")
  public ResponseEntity<Map<String, Object>> resetConfig() {
    Map<String, Object> response = new HashMap<>();

    try {
      configService.resetConfig();

      response.put("status", true);
      response.put("statuscode", 200);
      response.put("message", "Configuration reset successfully");
      response.put("timestamp", System.currentTimeMillis());

      return ResponseEntity.ok(response);

    } catch (Exception e) {
      response.put("status", false);
      response.put("statuscode", 500);
      response.put("message", "Error occurred while resetting configuration: " + e.getMessage());
      response.put("errorCode", "CONFIG_RESET_ERROR");

      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
  }
}

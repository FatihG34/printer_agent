package com.alpidiprinteragent.alpidiprinteragent.model;

public class PrinterInfo {
  private String name;
  private String status;

  public PrinterInfo() {}

  public PrinterInfo(String name, String status) {
    this.name = name;
    this.status = status;
  }

  // Getters & Setters
  public String getName() {
    return name;
  }

  public void setName(String name) {
    this.name = name;
  }

  public String getStatus() {
    return status;
  }

  public void setStatus(String status) {
    this.status = status;
  }
}

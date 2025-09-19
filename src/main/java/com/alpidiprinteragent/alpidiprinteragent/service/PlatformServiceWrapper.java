package com.alpidiprinteragent.alpidiprinteragent.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PlatformServiceWrapper {

  private static final Logger logger = LoggerFactory.getLogger(PlatformServiceWrapper.class);

  public static void main(String[] args) {
    String osName = System.getProperty("os.name").toLowerCase();

    logger.info("Detected OS: {}", osName);

    try {
      if (osName.contains("windows")) {
        logger.info("Starting Windows service wrapper...");
        WindowsServiceWrapper.main(args);
      } else if (osName.contains("mac") || osName.contains("darwin")) {
        logger.info("Starting macOS service wrapper...");
        MacServiceWrapper.main(args);
      } else if (osName.contains("linux") || osName.contains("unix")) {
        logger.info("Starting Linux service wrapper...");
        LinuxServiceWrapper.main(args);
      } else {
        logger.warn("Unknown OS: {}. Using generic Linux wrapper...", osName);
        LinuxServiceWrapper.main(args);
      }
    } catch (Exception e) {
      logger.error("Failed to start platform-specific service wrapper", e);
      // Fallback to direct application start
      logger.info("Falling back to direct application start...");
      com.alpidiprinteragent.alpidiprinteragent.AlpidiprinteragentApplication.main(args);
    }
  }
}

package com.alpidiprinteragent.alpidiprinteragent.service;

import com.alpidiprinteragent.alpidiprinteragent.AlpidiprinteragentApplication;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.IOException;
import java.net.URI;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.context.ConfigurableApplicationContext;

public class WindowsServiceWrapper {

  private static final Logger logger = LoggerFactory.getLogger(WindowsServiceWrapper.class);
  private static ConfigurableApplicationContext context;
  private static TrayIcon trayIcon;

  public static void main(String[] args) {
    // Check for headless argument or Windows service mode
    boolean forceHeadless = false;
    for (String arg : args) {
      if ("--headless".equals(arg) || "--service".equals(arg)) {
        forceHeadless = true;
        break;
      }
    }

    if (forceHeadless || GraphicsEnvironment.isHeadless()) {
      // Headless mode - just start the application
      System.setProperty("java.awt.headless", "true");
      logger.info("Starting Alpidi Printer Agent in headless mode...");
      startApplication(args);
    } else {
      // GUI mode - start with system tray
      logger.info("Starting Alpidi Printer Agent with system tray...");
      startWithSystemTray(args);
    }
  }

  private static void startApplication(String[] args) {
    try {
      logger.info("Starting Alpidi Printer Agent...");
      context = SpringApplication.run(AlpidiprinteragentApplication.class, args);
      logger.info("Alpidi Printer Agent started successfully on port 9000");
    } catch (Exception e) {
      logger.error("Failed to start Alpidi Printer Agent", e);
      System.exit(1);
    }
  }

  private static void startWithSystemTray(String[] args) {
    if (!SystemTray.isSupported()) {
      logger.warn("System tray is not supported, starting in console mode");
      startApplication(args);
      return;
    }

    // Create system tray icon
    createSystemTrayIcon();

    // Start the Spring Boot application
    startApplication(args);
  }

  private static void createSystemTrayIcon() {
    SystemTray tray = SystemTray.getSystemTray();

    // Create a simple tray icon image programmatically
    Image image = createTrayIconImage();

    // Create popup menu
    PopupMenu popup = new PopupMenu();

    MenuItem statusItem = new MenuItem("Alpidi Printer Agent - Running");
    statusItem.setEnabled(false);

    MenuItem openWebInterface = new MenuItem("Open Web Interface (localhost:9000)");
    openWebInterface.addActionListener(
        new ActionListener() {
          @Override
          public void actionPerformed(ActionEvent e) {
            try {
              Desktop.getDesktop().browse(URI.create("http://localhost:9000"));
            } catch (IOException ex) {
              logger.error("Failed to open web interface", ex);
              // Show error message to user
              trayIcon.displayMessage(
                  "Error",
                  "Could not open web browser. Please manually navigate to http://localhost:9000",
                  TrayIcon.MessageType.ERROR);
            }
          }
        });

    MenuItem restartItem = new MenuItem("Restart Application");
    restartItem.addActionListener(
        new ActionListener() {
          @Override
          public void actionPerformed(ActionEvent e) {
            try {
              // Restart the application
              if (context != null) {
                context.close();
              }
              // Start new instance
              startApplication(new String[] {});
              trayIcon.displayMessage(
                  "Alpidi Printer Agent",
                  "Application restarted successfully",
                  TrayIcon.MessageType.INFO);
            } catch (Exception ex) {
              logger.error("Failed to restart application", ex);
            }
          }
        });

    MenuItem exitItem = new MenuItem("Exit");
    exitItem.addActionListener(
        new ActionListener() {
          @Override
          public void actionPerformed(ActionEvent e) {
            trayIcon.displayMessage(
                "Alpidi Printer Agent",
                "Application is shutting down...",
                TrayIcon.MessageType.INFO);
            if (context != null) {
              context.close();
            }
            System.exit(0);
          }
        });

    popup.add(statusItem);
    popup.addSeparator();
    popup.add(openWebInterface);
    popup.add(restartItem);
    popup.addSeparator();
    popup.add(exitItem);

    // Create tray icon
    trayIcon = new TrayIcon(image, "Alpidi Printer Agent - Running on port 9000", popup);
    trayIcon.setImageAutoSize(true);

    // Double-click to open web interface
    trayIcon.addActionListener(
        new ActionListener() {
          @Override
          public void actionPerformed(ActionEvent e) {
            try {
              Desktop.getDesktop().browse(URI.create("http://localhost:9000"));
            } catch (IOException ex) {
              logger.error("Failed to open web interface", ex);
            }
          }
        });

    try {
      tray.add(trayIcon);
      trayIcon.displayMessage(
          "Alpidi Printer Agent",
          "Application started successfully!\nDouble-click to open web interface.",
          TrayIcon.MessageType.INFO);
    } catch (AWTException e) {
      logger.error("Failed to add tray icon", e);
    }
  }

  private static Image createTrayIconImage() {
    // Create a simple 16x16 icon programmatically
    int size = 16;
    java.awt.image.BufferedImage image =
        new java.awt.image.BufferedImage(size, size, java.awt.image.BufferedImage.TYPE_INT_ARGB);
    Graphics2D g2d = image.createGraphics();

    // Enable antialiasing
    g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

    // Draw a simple printer icon
    g2d.setColor(Color.DARK_GRAY);
    g2d.fillRect(2, 4, 12, 8);
    g2d.setColor(Color.LIGHT_GRAY);
    g2d.fillRect(3, 5, 10, 6);
    g2d.setColor(Color.BLACK);
    g2d.drawRect(2, 4, 12, 8);
    g2d.fillRect(6, 12, 4, 2);

    g2d.dispose();
    return image;
  }
}

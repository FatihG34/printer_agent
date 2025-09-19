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

public class MacServiceWrapper {

  private static final Logger logger = LoggerFactory.getLogger(MacServiceWrapper.class);
  private static ConfigurableApplicationContext context;
  private static TrayIcon trayIcon;

  public static void main(String[] args) {
    // Force headless mode for background service
    System.setProperty("java.awt.headless", "true");

    // Set macOS specific properties
    System.setProperty("apple.laf.useScreenMenuBar", "true");
    System.setProperty("com.apple.macos.use-file-dialog-packages", "true");
    System.setProperty("com.apple.macos.useScreenMenuBar", "true");
    System.setProperty("apple.awt.application.name", "Alpidi Printer Agent");

    // Always run in headless mode as a background service
    logger.info("Starting Alpidi Printer Agent in background mode...");
    startApplication(args);
  }

  private static void startApplication(String[] args) {
    try {
      logger.info("Starting Alpidi Printer Agent on macOS...");
      context = SpringApplication.run(AlpidiprinteragentApplication.class, args);
      logger.info("Alpidi Printer Agent started successfully on port 9000");
    } catch (Exception e) {
      logger.error("Failed to start Alpidi Printer Agent", e);
      System.exit(1);
    }
  }

  private static void startWithMenuBarIntegration(String[] args) {
    // Set up macOS integration
    setupMacOSIntegration();

    if (SystemTray.isSupported()) {
      // Create menu bar icon
      createMenuBarIcon();
    }

    // Start the Spring Boot application
    startApplication(args);
  }

  private static void setupMacOSIntegration() {
    try {
      // Use reflection to avoid compile-time dependency on macOS-specific classes
      Class<?> applicationClass = Class.forName("com.apple.eawt.Application");
      Object application = applicationClass.getMethod("getApplication").invoke(null);

      // Set dock icon name
      applicationClass.getMethod("setDockIconBadge", String.class).invoke(application, "");

      // Handle quit events
      Class<?> quitHandlerClass = Class.forName("com.apple.eawt.QuitHandler");
      Object quitHandler =
          java.lang.reflect.Proxy.newProxyInstance(
              quitHandlerClass.getClassLoader(),
              new Class[] {quitHandlerClass},
              (proxy, method, methodArgs) -> {
                if ("handleQuitRequestWith".equals(method.getName())) {
                  handleQuit();
                  // Get QuitResponse from args and call performQuit()
                  Object quitResponse = methodArgs[1];
                  quitResponse.getClass().getMethod("performQuit").invoke(quitResponse);
                }
                return null;
              });

      applicationClass
          .getMethod("setQuitHandler", quitHandlerClass)
          .invoke(application, quitHandler);

    } catch (Exception e) {
      logger.warn("Could not set up macOS integration: {}", e.getMessage());
    }
  }

  private static void createMenuBarIcon() {
    SystemTray tray = SystemTray.getSystemTray();

    // Create a simple menu bar icon
    Image image = createMenuBarIconImage();

    // Create popup menu
    PopupMenu popup = new PopupMenu();

    MenuItem statusItem = new MenuItem("Alpidi Printer Agent - Running");
    statusItem.setEnabled(false);

    MenuItem openWebInterface = new MenuItem("Open Web Interface");
    openWebInterface.addActionListener(
        new ActionListener() {
          @Override
          public void actionPerformed(ActionEvent e) {
            try {
              Desktop.getDesktop().browse(URI.create("http://localhost:9000"));
            } catch (IOException ex) {
              logger.error("Failed to open web interface", ex);
              showNotification(
                  "Error", "Could not open web browser. Please navigate to http://localhost:9000");
            }
          }
        });

    MenuItem restartItem = new MenuItem("Restart Application");
    restartItem.addActionListener(
        new ActionListener() {
          @Override
          public void actionPerformed(ActionEvent e) {
            try {
              if (context != null) {
                context.close();
              }
              startApplication(new String[] {});
              showNotification("Alpidi Printer Agent", "Application restarted successfully");
            } catch (Exception ex) {
              logger.error("Failed to restart application", ex);
            }
          }
        });

    MenuItem quitItem = new MenuItem("Quit");
    quitItem.addActionListener(
        new ActionListener() {
          @Override
          public void actionPerformed(ActionEvent e) {
            handleQuit();
          }
        });

    popup.add(statusItem);
    popup.addSeparator();
    popup.add(openWebInterface);
    popup.add(restartItem);
    popup.addSeparator();
    popup.add(quitItem);

    // Create menu bar icon
    trayIcon = new TrayIcon(image, "Alpidi Printer Agent", popup);
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
      showNotification(
          "Alpidi Printer Agent",
          "Application started successfully!\nClick the menu bar icon to access options.");
    } catch (AWTException e) {
      logger.error("Failed to add menu bar icon", e);
    }
  }

  private static Image createMenuBarIconImage() {
    // Create a simple 16x16 icon for macOS menu bar
    int size = 16;
    java.awt.image.BufferedImage image =
        new java.awt.image.BufferedImage(size, size, java.awt.image.BufferedImage.TYPE_INT_ARGB);
    Graphics2D g2d = image.createGraphics();

    // Enable antialiasing
    g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

    // Draw a simple printer icon optimized for macOS menu bar
    g2d.setColor(Color.BLACK);
    g2d.fillRect(2, 4, 12, 8);
    g2d.setColor(Color.WHITE);
    g2d.fillRect(3, 5, 10, 6);
    g2d.setColor(Color.BLACK);
    g2d.drawRect(2, 4, 12, 8);
    g2d.fillRect(6, 12, 4, 2);

    // Add a small dot to indicate active status
    g2d.setColor(Color.GREEN);
    g2d.fillOval(12, 2, 3, 3);

    g2d.dispose();
    return image;
  }

  private static void showNotification(String title, String message) {
    if (trayIcon != null) {
      trayIcon.displayMessage(title, message, TrayIcon.MessageType.INFO);
    }
  }

  private static void handleQuit() {
    showNotification("Alpidi Printer Agent", "Application is shutting down...");
    if (context != null) {
      context.close();
    }
    System.exit(0);
  }
}

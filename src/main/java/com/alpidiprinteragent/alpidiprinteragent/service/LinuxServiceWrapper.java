package com.alpidiprinteragent.alpidiprinteragent.service;

import com.alpidiprinteragent.alpidiprinteragent.AlpidiprinteragentApplication;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.IOException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.context.ConfigurableApplicationContext;

public class LinuxServiceWrapper {

  private static final Logger logger = LoggerFactory.getLogger(LinuxServiceWrapper.class);
  private static ConfigurableApplicationContext context;
  private static TrayIcon trayIcon;

  public static void main(String[] args) {
    // Check for service mode or headless arguments
    boolean forceHeadless = false;
    boolean isSystemdService = false;

    for (String arg : args) {
      if ("--headless".equals(arg) || "--service".equals(arg) || "--daemon".equals(arg)) {
        forceHeadless = true;
      }
      if ("--systemd".equals(arg)) {
        isSystemdService = true;
        forceHeadless = true;
      }
    }

    // Check if running as systemd service (no DISPLAY variable)
    if (System.getenv("DISPLAY") == null && !isDesktopEnvironment()) {
      forceHeadless = true;
    }

    if (forceHeadless || GraphicsEnvironment.isHeadless()) {
      // Headless mode for servers/services
      System.setProperty("java.awt.headless", "true");
      logger.info("Starting Alpidi Printer Agent in headless mode (Linux service)...");
      startApplication(args);
    } else {
      // Desktop mode with system tray (if supported)
      logger.info("Starting Alpidi Printer Agent with desktop integration...");
      startWithDesktopIntegration(args);
    }
  }

  private static boolean isDesktopEnvironment() {
    String[] desktopVars = {
      "XDG_CURRENT_DESKTOP", "DESKTOP_SESSION", "GNOME_DESKTOP_SESSION_ID", "KDE_SESSION_VERSION"
    };
    for (String var : desktopVars) {
      if (System.getenv(var) != null) {
        return true;
      }
    }
    return false;
  }

  private static void startApplication(String[] args) {
    try {
      logger.info("Starting Alpidi Printer Agent on Linux...");
      context = SpringApplication.run(AlpidiprinteragentApplication.class, args);
      logger.info("Alpidi Printer Agent started successfully on port 9000");

      // Keep the application running in headless mode
      if (GraphicsEnvironment.isHeadless()) {
        logger.info("Running in headless mode. Use Ctrl+C to stop.");
        // Add shutdown hook for graceful shutdown
        Runtime.getRuntime()
            .addShutdownHook(
                new Thread(
                    () -> {
                      logger.info("Shutting down Alpidi Printer Agent...");
                      if (context != null) {
                        context.close();
                      }
                    }));
      }
    } catch (Exception e) {
      logger.error("Failed to start Alpidi Printer Agent", e);
      System.exit(1);
    }
  }

  private static void startWithDesktopIntegration(String[] args) {
    // Try to create system tray if supported
    if (SystemTray.isSupported()) {
      createSystemTrayIcon();
    } else {
      logger.warn("System tray not supported on this Linux desktop environment");
    }

    // Start the Spring Boot application
    startApplication(args);
  }

  private static void createSystemTrayIcon() {
    try {
      SystemTray tray = SystemTray.getSystemTray();

      // Create a simple tray icon
      Image image = createTrayIconImage();

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
                // Try different browsers on Linux
                String[] browsers = {"xdg-open", "firefox", "chromium", "google-chrome", "opera"};
                boolean opened = false;

                for (String browser : browsers) {
                  try {
                    ProcessBuilder pb = new ProcessBuilder(browser, "http://localhost:9000");
                    pb.start();
                    opened = true;
                    break;
                  } catch (IOException ex) {
                    // Try next browser
                  }
                }

                if (!opened) {
                  logger.error(
                      "Could not open web browser. Please navigate to http://localhost:9000");
                  if (trayIcon != null) {
                    trayIcon.displayMessage(
                        "Info",
                        "Please open http://localhost:9000 in your browser",
                        TrayIcon.MessageType.INFO);
                  }
                }
              } catch (Exception ex) {
                logger.error("Failed to open web interface", ex);
              }
            }
          });

      MenuItem restartItem = new MenuItem("Restart Service");
      restartItem.addActionListener(
          new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
              try {
                if (context != null) {
                  context.close();
                }
                startApplication(new String[] {});
                if (trayIcon != null) {
                  trayIcon.displayMessage(
                      "Alpidi Printer Agent",
                      "Service restarted successfully",
                      TrayIcon.MessageType.INFO);
                }
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
              if (trayIcon != null) {
                trayIcon.displayMessage(
                    "Alpidi Printer Agent",
                    "Service is shutting down...",
                    TrayIcon.MessageType.INFO);
              }
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
      popup.add(quitItem);

      // Create tray icon
      trayIcon = new TrayIcon(image, "Alpidi Printer Agent", popup);
      trayIcon.setImageAutoSize(true);

      // Double-click to open web interface
      trayIcon.addActionListener(
          new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
              try {
                ProcessBuilder pb = new ProcessBuilder("xdg-open", "http://localhost:9000");
                pb.start();
              } catch (IOException ex) {
                logger.error("Failed to open web interface", ex);
              }
            }
          });

      tray.add(trayIcon);
      trayIcon.displayMessage(
          "Alpidi Printer Agent",
          "Service started successfully!\nWeb interface: http://localhost:9000",
          TrayIcon.MessageType.INFO);

    } catch (AWTException e) {
      logger.error("Failed to create system tray icon", e);
    }
  }

  private static Image createTrayIconImage() {
    // Create a simple 16x16 icon for Linux system tray
    int size = 16;
    java.awt.image.BufferedImage image =
        new java.awt.image.BufferedImage(size, size, java.awt.image.BufferedImage.TYPE_INT_ARGB);
    Graphics2D g2d = image.createGraphics();

    // Enable antialiasing
    g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

    // Draw a simple printer icon optimized for Linux system tray
    g2d.setColor(Color.BLACK);
    g2d.fillRect(2, 4, 12, 8);
    g2d.setColor(Color.WHITE);
    g2d.fillRect(3, 5, 10, 6);
    g2d.setColor(Color.BLACK);
    g2d.drawRect(2, 4, 12, 8);
    g2d.fillRect(6, 12, 4, 2);

    // Add a small indicator
    g2d.setColor(Color.BLUE);
    g2d.fillOval(12, 2, 3, 3);

    g2d.dispose();
    return image;
  }
}

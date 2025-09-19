# Deployment Guide

This guide covers deployment strategies and platform-specific instructions for the Alpidi Printer Agent.

## 🎯 Deployment Overview

The Alpidi Printer Agent can be deployed in several ways depending on your target platform and requirements:

- **Standalone Executable**: Self-contained applications for each platform
- **Java JAR**: Cross-platform JAR file requiring Java runtime
- **System Service**: Background service installation
- **Portable Mode**: No-installation required versions

## 🪟 Windows Deployment

### Option 1: Portable Executable (Recommended)

The portable version provides the best user experience:

```bash
# Build portable version
./build-windows.bat
```

**Generated Files:**
- `AlpidiPrinterAgent-Portable.exe` - Self-extracting, no installation required
- `AlpidiPrinterAgentAutoInstaller.exe` - Silent installer with auto-start
- `alpidi-printer-agent.exe` - Standard executable (requires Java 17+)

**User Experience:**
1. User downloads `AlpidiPrinterAgent-Portable.exe`
2. Double-clicks to run
3. Application automatically:
   - Extracts to temporary location
   - Starts the service
   - Creates system tray icon
   - Adds to Windows startup (optional)
   - Creates desktop shortcut

### Option 2: Windows Service Installation

For enterprise deployments, install as a Windows service:

```batch
# Install as service (requires admin privileges)
sc create "AlpidiPrinterAgent" binPath="C:\path\to\alpidi-printer-agent.exe" start=auto
sc description "AlpidiPrinterAgent" "Alpidi Printer Agent Service"
sc start "AlpidiPrinterAgent"
```

### Option 3: MSI Installer (Advanced)

For enterprise distribution, create an MSI package:

```bash
# Requires WiX Toolset
candle installer.wxs
light installer.wixobj -out AlpidiPrinterAgent.msi
```

### Windows Registry Configuration

The application can store configuration in Windows Registry:

```registry
[HKEY_CURRENT_USER\Software\Alpidi\PrinterAgent]
"ActivePrinter"="HP LaserJet Pro"
"AutoStart"=dword:00000001
"Port"=dword:00002328
```

## 🍎 macOS Deployment

### Option 1: Application Bundle (Recommended)

```bash
# Build macOS app bundle
./build-mac.sh
```

**Generated Files:**
- `Alpidi Printer Agent.app` - Native macOS application
- `AlpidiPrinterAgent.dmg` - Professional installer
- `AlpidiPrinterAgent-macOS.zip` - ZIP archive alternative

**Installation Process:**
1. User downloads the DMG file
2. Mounts the disk image
3. Drags the app to Applications folder
4. Launches from Applications or Spotlight

### Option 2: Homebrew Distribution

Create a Homebrew formula for easy installation:

```ruby
# alpidi-printer-agent.rb
class AlpidiPrinterAgent < Formula
  desc "Local printer management service for Alpidi applications"
  homepage "https://alpidi.com"
  url "https://github.com/alpidi/printer-agent/releases/download/v1.0.0/alpidi-printer-agent.jar"
  sha256 "..."
  
  depends_on "openjdk@17"
  
  def install
    libexec.install "alpidi-printer-agent.jar"
    bin.write_jar_script libexec/"alpidi-printer-agent.jar", "alpidi-printer-agent"
  end
  
  service do
    run [opt_bin/"alpidi-printer-agent"]
    keep_alive true
    log_path var/"log/alpidi-printer-agent.log"
    error_log_path var/"log/alpidi-printer-agent.log"
  end
end
```

### Option 3: LaunchAgent (Background Service)

For automatic startup, create a LaunchAgent:

```xml
<!-- ~/Library/LaunchAgents/com.alpidi.printeragent.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.alpidi.printeragent</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/java</string>
        <string>-jar</string>
        <string>/Applications/Alpidi Printer Agent.app/Contents/Java/alpidi-printer-agent.jar</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

Load the service:
```bash
launchctl load ~/Library/LaunchAgents/com.alpidi.printeragent.plist
```

## 🐧 Linux Deployment

### Option 1: Package Installation (Recommended)

```bash
# Build Linux packages
./build-linux.sh
```

**Generated Packages:**
- `alpidiprinteragent_0.0.1-SNAPSHOT_all.deb` - Debian/Ubuntu package
- `alpidiprinteragent-0.0.1-SNAPSHOT.noarch.rpm` - Red Hat/CentOS package

**Installation:**
```bash
# Debian/Ubuntu
sudo dpkg -i alpidiprinteragent_0.0.1-SNAPSHOT_all.deb
sudo apt-get install -f  # Fix dependencies if needed

# Red Hat/CentOS
sudo rpm -ivh alpidiprinteragent-0.0.1-SNAPSHOT.noarch.rpm
```

### Option 2: Systemd Service

The Linux packages automatically install a systemd service:

```bash
# Control the service
sudo systemctl start alpidi-printer-agent
sudo systemctl enable alpidi-printer-agent
sudo systemctl status alpidi-printer-agent

# View logs
journalctl -u alpidi-printer-agent -f
```

### Option 3: Manual Installation

For custom installations:

```bash
# Create user and directories
sudo useradd -r -s /bin/false alpidi-printer-agent
sudo mkdir -p /opt/alpidi-printer-agent
sudo mkdir -p /var/log/alpidi-printer-agent

# Copy files
sudo cp target/alpidiprinteragent-*-exec.jar /opt/alpidi-printer-agent/alpidi-printer-agent.jar
sudo chown -R alpidi-printer-agent:alpidi-printer-agent /opt/alpidi-printer-agent
sudo chown -R alpidi-printer-agent:alpidi-printer-agent /var/log/alpidi-printer-agent

# Create systemd service
sudo cp src/linux/alpidi-printer-agent.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable alpidi-printer-agent
sudo systemctl start alpidi-printer-agent
```

## 🐳 Docker Deployment

### Dockerfile

```dockerfile
FROM openjdk:17-jre-slim

# Install CUPS for printer support
RUN apt-get update && apt-get install -y \
    cups \
    cups-client \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy application
COPY target/alpidiprinteragent-*-exec.jar app.jar

# Expose port
EXPOSE 9000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:9000/i-am-here || exit 1

# Run application
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Docker Compose

```yaml
version: '3.8'
services:
  alpidi-printer-agent:
    build: .
    ports:
      - "9000:9000"
    volumes:
      - /var/run/cups/cups.sock:/var/run/cups/cups.sock
      - ./config:/app/config
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - SERVER_PORT=9000
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/i-am-here"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alpidi-printer-agent
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alpidi-printer-agent
  template:
    metadata:
      labels:
        app: alpidi-printer-agent
    spec:
      containers:
      - name: alpidi-printer-agent
        image: alpidi/printer-agent:latest
        ports:
        - containerPort: 9000
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "kubernetes"
        livenessProbe:
          httpGet:
            path: /i-am-here
            port: 9000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /i-am-here
            port: 9000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: alpidi-printer-agent-service
spec:
  selector:
    app: alpidi-printer-agent
  ports:
  - protocol: TCP
    port: 9000
    targetPort: 9000
  type: LoadBalancer
```

## 🌐 Cloud Deployment

### AWS EC2

```bash
# User data script for EC2 instance
#!/bin/bash
yum update -y
yum install -y java-17-openjdk

# Download and install the application
wget https://releases.alpidi.com/printer-agent/alpidi-printer-agent.jar
mkdir -p /opt/alpidi-printer-agent
mv alpidi-printer-agent.jar /opt/alpidi-printer-agent/

# Create systemd service
cat > /etc/systemd/system/alpidi-printer-agent.service << EOF
[Unit]
Description=Alpidi Printer Agent
After=network.target

[Service]
Type=simple
User=ec2-user
ExecStart=/usr/bin/java -jar /opt/alpidi-printer-agent/alpidi-printer-agent.jar
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable alpidi-printer-agent
systemctl start alpidi-printer-agent
```

### Azure VM

```powershell
# PowerShell script for Azure VM
# Install Java
Invoke-WebRequest -Uri "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.exe" -OutFile "jdk-installer.exe"
Start-Process -FilePath "jdk-installer.exe" -ArgumentList "/s" -Wait

# Download and install application
Invoke-WebRequest -Uri "https://releases.alpidi.com/printer-agent/alpidi-printer-agent.exe" -OutFile "C:\Program Files\Alpidi\alpidi-printer-agent.exe"

# Create Windows service
New-Service -Name "AlpidiPrinterAgent" -BinaryPathName "C:\Program Files\Alpidi\alpidi-printer-agent.exe" -StartupType Automatic
Start-Service -Name "AlpidiPrinterAgent"
```

## 🔧 Configuration Management

### Environment Variables

The application supports configuration via environment variables:

```bash
export SERVER_PORT=9000
export BACKEND_BASE_URL=http://localhost:8080
export SPRING_PROFILES_ACTIVE=production
export LOGGING_LEVEL_ROOT=INFO
```

### Configuration Files

Create environment-specific configuration files:

```properties
# application-production.properties
server.port=9000
backend.base-url=https://api.alpidi.com
logging.level.com.alpidiprinteragent=INFO
management.endpoints.web.exposure.include=health,info,metrics
```

### External Configuration

Use Spring Boot's external configuration capabilities:

```bash
# Run with external config
java -jar alpidi-printer-agent.jar --spring.config.location=file:./config/application.properties
```

## 📊 Monitoring and Health Checks

### Health Check Endpoint

```bash
# Check application health
curl http://localhost:9000/i-am-here
```

### Metrics (with Actuator)

Add Spring Boot Actuator for monitoring:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

Access metrics at:
- `http://localhost:9000/actuator/health`
- `http://localhost:9000/actuator/metrics`
- `http://localhost:9000/actuator/info`

### Log Configuration

Configure logging for production:

```xml
<!-- logback-spring.xml -->
<configuration>
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>logs/alpidi-printer-agent.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>logs/alpidi-printer-agent.%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>30</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    
    <root level="INFO">
        <appender-ref ref="FILE" />
    </root>
</configuration>
```

## 🔒 Security Considerations

### Network Security

- Run on localhost only by default
- Use HTTPS in production environments
- Implement API authentication if needed

### File Permissions

```bash
# Secure file permissions (Linux)
chmod 600 printer-config.json
chown alpidi-printer-agent:alpidi-printer-agent printer-config.json
```

### Firewall Configuration

```bash
# Linux firewall rules
sudo ufw allow 9000/tcp
sudo ufw reload

# Windows firewall
netsh advfirewall firewall add rule name="Alpidi Printer Agent" dir=in action=allow protocol=TCP localport=9000
```

## 🚀 Scaling and Load Balancing

For high-availability deployments:

### Load Balancer Configuration

```nginx
# Nginx configuration
upstream alpidi_printer_agents {
    server 127.0.0.1:9000;
    server 127.0.0.1:9001;
    server 127.0.0.1:9002;
}

server {
    listen 80;
    server_name printer-agent.alpidi.com;
    
    location / {
        proxy_pass http://alpidi_printer_agents;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Multiple Instance Deployment

```bash
# Run multiple instances
java -jar alpidi-printer-agent.jar --server.port=9000 &
java -jar alpidi-printer-agent.jar --server.port=9001 &
java -jar alpidi-printer-agent.jar --server.port=9002 &
```

## 📋 Deployment Checklist

### Pre-deployment

- [ ] Java 17+ installed on target system
- [ ] Required printers installed and accessible
- [ ] Network connectivity to Alpidi backend
- [ ] Firewall rules configured
- [ ] SSL certificates installed (if using HTTPS)

### Deployment

- [ ] Application deployed to target location
- [ ] Configuration files updated for environment
- [ ] Service/daemon configured for auto-start
- [ ] Health checks passing
- [ ] Logs configured and accessible

### Post-deployment

- [ ] Application accessible via web interface
- [ ] Printer discovery working
- [ ] Print functionality tested
- [ ] Background synchronization working
- [ ] Monitoring and alerting configured

## 🆘 Troubleshooting Deployment Issues

### Common Issues

1. **Port Already in Use**
   ```bash
   # Find process using port
   netstat -tulpn | grep :9000
   # Kill process or change port
   ```

2. **Java Not Found**
   ```bash
   # Check Java installation
   java -version
   # Install Java if missing
   ```

3. **Permission Denied**
   ```bash
   # Fix file permissions
   chmod +x alpidi-printer-agent.jar
   ```

4. **Service Won't Start**
   ```bash
   # Check service logs
   journalctl -u alpidi-printer-agent -f
   ```

### Log Analysis

Common log patterns to watch for:

```
# Successful startup
Started AlpidiprinteragentApplication in X.XXX seconds

# Printer discovery
Found X printers: [printer1, printer2, ...]

# Configuration loaded
Configuration loaded from printer-config.json

# Sync completed
[SYNC] Local active printer updated to: PrinterName
```

---

This deployment guide covers all major deployment scenarios. Choose the approach that best fits your infrastructure and requirements.
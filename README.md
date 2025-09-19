# Alpidi Printer Agent

A Spring Boot application that serves as a local printer management service for the Alpidi application ecosystem. It acts as a bridge between Alpidi web applications and local system printers, providing seamless printing capabilities across different platforms.

## 🚀 Overview

The Alpidi Printer Agent is a lightweight, cross-platform service that enables Alpidi web applications to interact with local printers. It provides a RESTful API for printer discovery, configuration, and PDF printing operations.

### Key Features

- **Automatic Printer Discovery**: Detects and lists all available system printers
- **Printer Management**: Set and retrieve active printer configurations
- **PDF Printing**: Accept Base64-encoded PDF data and print to configured printers
- **Cross-Platform Support**: Runs on Windows, macOS, and Linux
- **Web Interface**: Accessible via http://localhost:9000
- **CORS Support**: Configured for multiple Alpidi environments
- **Background Synchronization**: Automatic printer configuration sync with Alpidi backend
- **File-based Configuration**: Local storage for printer settings

## 🏗️ Architecture

### Technology Stack

- **Java 24**: Latest Java version with modern language features
- **Spring Boot 3.5.5**: Main application framework
- **Maven**: Build system and dependency management
- **Spring Web**: RESTful web services with embedded Tomcat
- **Spring Scheduling**: Background tasks and synchronization
- **Java Print API**: System printer integration

### Project Structure

```
src/main/java/com/alpidiprinteragent/alpidiprinteragent/
├── AlpidiprinteragentApplication.java    # Main Spring Boot application
├── controller/
│   └── PrinterController.java           # REST API endpoints
├── service/
│   ├── PrinterService.java              # Core printer operations
│   ├── ConfigService.java               # Configuration management
│   └── PrinterSyncService.java          # Background synchronization
└── model/
    └── PrinterInfo.java                 # Data transfer objects
```

## 📋 API Documentation

### Base URL
```
http://localhost:9000
```

### Endpoints

#### Health Check
```http
GET /i-am-here
```
Returns agent status and availability.

**Response:**
```json
{
  "status": true,
  "message": "The agent already exist",
  "timestamp": 1640995200000
}
```

#### Get Available Printers
```http
GET /printers
```
Returns a list of available printer names.

**Response:**
```json
[
  "HP LaserJet Pro",
  "Canon PIXMA",
  "Microsoft Print to PDF"
]
```

#### Get Detailed Printer Information
```http
GET /printers-details
```
Returns detailed information about all available printers.

**Response:**
```json
[
  {
    "name": "HP LaserJet Pro",
    "location": "Office Floor 2",
    "uri": "ipp://192.168.1.100:631/printers/hp-laserjet",
    "allAttributes": "printer-state: idle, printer-type: laser"
  }
]
```

#### Set Active Printer
```http
POST /printers/active
Content-Type: application/json

{
  "printerName": "HP LaserJet Pro",
  "productionPartnerUserId": "123"
}
```

**Response:**
```json
{
  "status": true,
  "message": "Active printer successfully set to: HP LaserJet Pro",
  "activePrinter": "HP LaserJet Pro",
  "timestamp": 1640995200000
}
```

#### Print PDF Document
```http
POST /print
Content-Type: application/json

{
  "fileName": "document.pdf",
  "pdfData": "JVBERi0xLjQKJcOkw7zDtsO..."
}
```

**Response:**
```json
{
  "status": true,
  "statuscode": 200,
  "message": "Print job completed successfully",
  "data": {
    "printerName": "HP LaserJet Pro",
    "fileName": "document.pdf",
    "timestamp": 1640995200000,
    "documentSize": 25600
  }
}
```

#### Get Configuration
```http
GET /config
```
Returns current agent configuration.

#### Update Print Settings
```http
POST /config/print-settings
Content-Type: application/json

{
  "copies": 1,
  "orientation": "portrait",
  "paperSize": "A4"
}
```

#### Reset Configuration
```http
POST /config/reset
```
Resets all configuration to defaults.

## 🛠️ Installation & Setup

### Prerequisites

- **Java 17+** (for development and manual execution)
- **Maven 3.6+** (for building from source)

### Quick Start

1. **Download the appropriate version for your platform:**
   - Windows: `alpidi-printer-agent.exe` or `AlpidiPrinterAgent-Portable.exe`
   - macOS: `Alpidi Printer Agent.app` or `AlpidiPrinterAgent.dmg`
   - Linux: `alpidi-printer-agent.jar` with launcher script

2. **Run the application:**
   - Windows: Double-click the `.exe` file
   - macOS: Drag `.app` to Applications and launch
   - Linux: Execute `./launch-alpidi-printer-agent.sh`

3. **Access the web interface:**
   - Open your browser and navigate to `http://localhost:9000`

### Building from Source

```bash
# Clone the repository
git clone <repository-url>
cd alpidi-printer-agent

# Build for all platforms
./build-all.sh

# Or build for specific platforms
./build-windows.bat    # Windows
./build-mac.sh         # macOS
./build-linux.sh       # Linux

# Or use Maven directly
./mvnw clean package
java -jar target/alpidiprinteragent-0.0.1-SNAPSHOT-exec.jar
```

## ⚙️ Configuration

### Application Properties

The application can be configured via `src/main/resources/application.properties`:

```properties
# Application name
spring.application.name=alpidiprinteragent

# Server port
server.port=9000

# Disable Spring Boot banner
spring.main.banner-mode=off

# Logging configuration
logging.level.org.springframework=ERROR

# Backend URL for synchronization
backend.base-url=http://localhost:8080
```

### Runtime Configuration

The agent stores its configuration in `printer-config.json` in the application directory:

```json
{
  "activePrinter": "HP LaserJet Pro",
  "productionPartnerUserId": "123",
  "lastUpdated": 1640995200000,
  "printSettings": {
    "copies": 1,
    "orientation": "portrait",
    "paperSize": "A4"
  }
}
```

## 🔄 Background Services

### Printer Synchronization

The agent includes a background service that synchronizes printer configuration with the Alpidi backend:

- **Schedule**: Daily at 7:00 AM (America/New_York timezone)
- **Function**: Retrieves default printer settings from backend
- **Endpoint**: `GET /api/public/printer/{userId}/default-active`
- **Behavior**: Updates local configuration if backend settings differ

## 🌐 CORS Configuration

The application is configured to accept requests from multiple Alpidi domains:

- `http://localhost:4200` (Development)
- `https://alpidi.com` (Production)
- `https://app.alpidi.com` (Application)
- `https://test.alpidi.com` (Testing)
- `https://stage.alpidi.com` (Staging)

## 🔧 Development

### Running in Development Mode

```bash
# Start the application with Maven
./mvnw spring-boot:run

# Or run with specific profile
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

### Testing

```bash
# Run all tests
./mvnw test

# Run with coverage
./mvnw test jacoco:report
```

### Building Native Images

The project supports GraalVM native image compilation:

```bash
# Build native image
./mvnw clean package -Pnative
```

## 📦 Distribution

### Windows Distribution

- **Standard Executable**: `alpidi-printer-agent.exe` (requires Java 17+)
- **Portable Version**: `AlpidiPrinterAgent-Portable.exe` (self-contained)
- **Auto Installer**: `AlpidiPrinterAgentAutoInstaller.exe` (silent installation)

### macOS Distribution

- **Application Bundle**: `Alpidi Printer Agent.app`
- **DMG Installer**: `AlpidiPrinterAgent.dmg`
- **ZIP Archive**: `AlpidiPrinterAgent-macOS.zip`

### Linux Distribution

- **DEB Package**: For Debian/Ubuntu systems
- **RPM Package**: For Red Hat/CentOS systems
- **JAR + Scripts**: Universal Linux compatibility

## 🐛 Troubleshooting

### Common Issues

#### Port 9000 Already in Use
```bash
# Check what's using the port
lsof -i :9000  # macOS/Linux
netstat -ano | findstr :9000  # Windows

# Kill the process or change the port in application.properties
```

#### Printer Not Found
- Ensure the printer is installed and accessible
- Check printer name spelling (case-sensitive)
- Verify printer drivers are installed

#### Java Not Found (Windows .exe)
- Install Java 17+ from [Oracle](https://www.oracle.com/java/technologies/downloads/) or [OpenJDK](https://openjdk.org/)
- Or use the portable version which includes Java runtime

#### CORS Errors
- Verify the requesting domain is in the CORS configuration
- Check browser console for specific CORS error messages

### Logging

Enable debug logging by modifying `application.properties`:

```properties
logging.level.com.alpidiprinteragent=DEBUG
logging.level.org.springframework.web=DEBUG
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Java naming conventions
- Use Spring Boot best practices
- Include unit tests for new features
- Document public APIs with JavaDoc

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:

- **Documentation**: This README and inline code comments
- **Issues**: Create an issue in the repository
- **Email**: Contact the Alpidi development team

## 🔄 Version History

- **v0.0.1-SNAPSHOT**: Initial release
  - Basic printer discovery and management
  - PDF printing capabilities
  - Cross-platform support
  - Web interface
  - Background synchronization

---

**Made with ❤️ by the Alpidi Team**
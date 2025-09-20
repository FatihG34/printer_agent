# API Reference

Complete API documentation for the Alpidi Printer Agent REST endpoints.

## 🌐 Base Information

- **Base URL**: `http://localhost:9000`
- **Content-Type**: `application/json`
- **CORS Enabled**: Yes (for Alpidi domains)
- **Authentication**: None (local service)

## 📋 Supported Domains

The API accepts requests from the following origins:
- `http://localhost:4200` (Development)
- `https://alpidi.com` (Production)
- `https://app.alpidi.com` (Application)
- `https://test.alpidi.com` (Testing)
- `https://stage.alpidi.com` (Staging)

## 🔍 Health Check

### Check Agent Status

Verify that the Alpidi Printer Agent is running and accessible.

```http
GET /i-am-here
```

#### Response

```json
{
  "status": true,
  "message": "The agent already exist",
  "timestamp": 1640995200000
}
```

#### Response Codes
- `200 OK`: Agent is running successfully

---

## 🖨️ Printer Management

### List Available Printers

Get a simple list of all available printer names on the system.

```http
GET /printers
```

#### Response

```json
[
  "HP LaserJet Pro M404n",
  "Canon PIXMA TS3300",
  "Microsoft Print to PDF",
  "Brother HL-L2350DW"
]
```

#### Response Codes
- `200 OK`: Successfully retrieved printer list

---

### Get Detailed Printer Information

Retrieve comprehensive information about all available printers including location, URI, and attributes.

```http
GET /printers-details
```

#### Response

```json
[
  {
    "name": "HP LaserJet Pro M404n",
    "location": "Office Floor 2, Room 201",
    "uri": "ipp://192.168.1.100:631/printers/hp-laserjet",
    "allAttributes": "printer-state: idle, printer-type: laser, color-supported: false, sides-supported: two-sided-long-edge"
  },
  {
    "name": "Canon PIXMA TS3300",
    "location": "Home Office",
    "uri": "usb://Canon/PIXMA%20TS3300",
    "allAttributes": "printer-state: idle, printer-type: inkjet, color-supported: true, resolution-supported: 4800x1200dpi"
  },
  {
    "name": "Microsoft Print to PDF",
    "location": "Not specified",
    "uri": null,
    "allAttributes": "printer-state: idle, printer-type: virtual"
  }
]
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Printer display name |
| `location` | string | Physical location of the printer |
| `uri` | string/null | Network URI for the printer (if available) |
| `allAttributes` | string | Comma-separated list of printer capabilities |

#### Response Codes
- `200 OK`: Successfully retrieved detailed printer information

---

### Set Active Printer

Configure which printer should be used for print operations.

```http
POST /printers/active
Content-Type: application/json
```

#### Request Body

```json
{
  "printerName": "HP LaserJet Pro M404n",
  "productionPartnerUserId": "123"
}
```

#### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `printerName` | string | Yes | Exact name of the printer to set as active |
| `productionPartnerUserId` | string | No | User ID for synchronization with backend |

#### Success Response

```json
{
  "status": true,
  "message": "Active printer successfully set to: HP LaserJet Pro M404n",
  "activePrinter": "HP LaserJet Pro M404n",
  "timestamp": 1640995200000
}
```

#### Error Responses

**Missing Printer Name (400 Bad Request)**
```json
{
  "status": false,
  "message": "Printer name cannot be empty",
  "errorCode": "PRINTER_NAME_REQUIRED"
}
```

**Internal Error (500 Internal Server Error)**
```json
{
  "status": false,
  "message": "Error occurred while setting printer: [error details]",
  "errorCode": "PRINTER_SET_ERROR"
}
```

#### Response Codes
- `200 OK`: Printer successfully set as active
- `400 Bad Request`: Invalid request parameters
- `500 Internal Server Error`: Server error occurred

---

## 📄 Print Operations

### Print PDF Document

Send a Base64-encoded PDF document to the active printer.

```http
POST /print
Content-Type: application/json
```

#### Request Body

```json
{
  "fileName": "invoice_2024_001.pdf",
  "pdfData": "JVBERi0xLjQKJcOkw7zDtsO8w6HDqMOgCjIgMCBvYmoKPDwKL0xlbmd0aCAzIDAgUgovRmlsdGVyIC9GbGF0ZURlY29kZQo+PgpzdHJlYW0KeAGFkMENwzAMBHdRwQVoiZZEbxPEQIE2QOIiTYuk7d9XhtsUKHCHOxwOh..."
}
```

#### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `fileName` | string | No | Name of the PDF file (for logging purposes) |
| `pdfData` | string | Yes | Base64-encoded PDF document data |

#### Success Response

```json
{
  "status": true,
  "statuscode": 200,
  "message": "Print job completed successfully",
  "data": {
    "printerName": "HP LaserJet Pro M404n",
    "fileName": "invoice_2024_001.pdf",
    "timestamp": 1640995200000,
    "documentSize": 25600
  }
}
```

#### Error Responses

**Missing PDF Data (400 Bad Request)**
```json
{
  "status": false,
  "statuscode": 404,
  "message": "PDF data cannot be null or empty",
  "data": "PDF_DATA_REQUIRED"
}
```

**No Active Printer (400 Bad Request)**
```json
{
  "status": false,
  "statuscode": 404,
  "message": "No active printer configured. Please select a printer first.",
  "data": "NO_ACTIVE_PRINTER"
}
```

**Invalid PDF Format (400 Bad Request)**
```json
{
  "status": false,
  "statuscode": 404,
  "message": "Invalid PDF data format",
  "data": "Illegal base64 character 2e"
}
```

**Print Error (500 Internal Server Error)**
```json
{
  "status": false,
  "statuscode": 500,
  "message": "Print operation failed: Printer not found: HP LaserJet Pro M404n",
  "data": {
    "errorCode": "PRINT_ERROR",
    "timestamp": 1640995200000
  }
}
```

#### Response Codes
- `200 OK`: Document printed successfully
- `400 Bad Request`: Invalid request or missing active printer
- `500 Internal Server Error`: Print operation failed

---

## ⚙️ Configuration Management

### Get Current Configuration

Retrieve the current agent configuration including active printer and settings.

```http
GET /config
```

#### Response

```json
{
  "activePrinter": "HP LaserJet Pro M404n",
  "productionPartnerUserId": "123",
  "lastUpdated": 1640995200000,
  "printSettings": {
    "copies": 1,
    "orientation": "portrait",
    "paperSize": "A4",
    "quality": "normal"
  }
}
```

#### Response Codes
- `200 OK`: Configuration retrieved successfully

---

### Update Print Settings

Modify print settings such as copies, orientation, and paper size.

```http
POST /config/print-settings
Content-Type: application/json
```

#### Request Body

```json
{
  "copies": 2,
  "orientation": "landscape",
  "paperSize": "A3",
  "quality": "high",
  "duplex": "two-sided-long-edge"
}
```

#### Supported Settings

| Setting | Type | Values | Description |
|---------|------|--------|-------------|
| `copies` | integer | 1-99 | Number of copies to print |
| `orientation` | string | `portrait`, `landscape` | Page orientation |
| `paperSize` | string | `A4`, `A3`, `Letter`, `Legal` | Paper size |
| `quality` | string | `draft`, `normal`, `high` | Print quality |
| `duplex` | string | `one-sided`, `two-sided-long-edge`, `two-sided-short-edge` | Duplex printing |

#### Success Response

```json
{
  "status": true,
  "statuscode": 201,
  "message": "Print settings updated successfully",
  "updatedSettings": {
    "copies": 2,
    "orientation": "landscape",
    "paperSize": "A3",
    "quality": "high",
    "duplex": "two-sided-long-edge"
  },
  "timestamp": 1640995200000
}
```

#### Error Response

```json
{
  "status": false,
  "statuscode": 500,
  "message": "Error occurred while updating settings: [error details]",
  "errorCode": "SETTINGS_UPDATE_ERROR"
}
```

#### Response Codes
- `200 OK`: Settings updated successfully
- `500 Internal Server Error`: Failed to update settings

---

### Reset Configuration

Reset all configuration to default values and clear the active printer.

```http
POST /config/reset
```

#### Success Response

```json
{
  "status": true,
  "statuscode": 200,
  "message": "Configuration reset successfully",
  "timestamp": 1640995200000
}
```

#### Error Response

```json
{
  "status": false,
  "statuscode": 500,
  "message": "Error occurred while resetting configuration: [error details]",
  "errorCode": "CONFIG_RESET_ERROR"
}
```

#### Response Codes
- `200 OK`: Configuration reset successfully
- `500 Internal Server Error`: Failed to reset configuration

---

## 🔄 Background Services

The agent includes background services that operate automatically:

### Printer Synchronization

- **Schedule**: Daily at 7:00 AM (America/New_York timezone)
- **Function**: Synchronizes active printer with Alpidi backend
- **Endpoint Called**: `GET {backend.base-url}/api/public/printer/{userId}/default-active`
- **Behavior**: Updates local configuration if backend differs

---

## 📊 Error Codes Reference

| Error Code | HTTP Status | Description |
|------------|-------------|-------------|
| `PRINTER_NAME_REQUIRED` | 400 | Printer name is missing or empty |
| `PRINTER_SET_ERROR` | 500 | Failed to set active printer |
| `PDF_DATA_REQUIRED` | 400 | PDF data is missing or empty |
| `NO_ACTIVE_PRINTER` | 400 | No printer configured for printing |
| `PRINT_ERROR` | 500 | Print operation failed |
| `SETTINGS_UPDATE_ERROR` | 500 | Failed to update print settings |
| `CONFIG_RESET_ERROR` | 500 | Failed to reset configuration |

---

## 🧪 Testing the API

### Using cURL

#### Check Agent Status
```bash
curl -X GET http://localhost:9000/i-am-here
```

#### List Printers
```bash
curl -X GET http://localhost:9000/printers
```

#### Set Active Printer
```bash
curl -X POST http://localhost:9000/printers/active \
  -H "Content-Type: application/json" \
  -d '{"printerName": "HP LaserJet Pro M404n", "productionPartnerUserId": "123"}'
```

#### Print PDF (with sample Base64 data)
```bash
curl -X POST http://localhost:9000/print \
  -H "Content-Type: application/json" \
  -d '{"fileName": "test.pdf", "pdfData": "JVBERi0xLjQKJcOkw7zDtsO8..."}'
```

### Using JavaScript/Fetch

```javascript
// Check agent status
const checkStatus = async () => {
  const response = await fetch('http://localhost:9000/i-am-here');
  const data = await response.json();
  console.log('Agent status:', data);
};

// Set active printer
const setActivePrinter = async (printerName, userId) => {
  const response = await fetch('http://localhost:9000/printers/active', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      printerName: printerName,
      productionPartnerUserId: userId
    })
  });
  const data = await response.json();
  console.log('Set printer result:', data);
};

// Print PDF
const printPDF = async (fileName, base64Data) => {
  const response = await fetch('http://localhost:9000/print', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      fileName: fileName,
      pdfData: base64Data
    })
  });
  const data = await response.json();
  console.log('Print result:', data);
};
```

### Using Python

```python
import requests
import base64

# Base URL
BASE_URL = "http://localhost:9000"

# Check agent status
def check_status():
    response = requests.get(f"{BASE_URL}/i-am-here")
    return response.json()

# List printers
def list_printers():
    response = requests.get(f"{BASE_URL}/printers")
    return response.json()

# Set active printer
def set_active_printer(printer_name, user_id):
    data = {
        "printerName": printer_name,
        "productionPartnerUserId": user_id
    }
    response = requests.post(f"{BASE_URL}/printers/active", json=data)
    return response.json()

# Print PDF file
def print_pdf_file(file_path, printer_name=None):
    # Set printer if specified
    if printer_name:
        set_active_printer(printer_name, "123")
    
    # Read and encode PDF
    with open(file_path, 'rb') as file:
        pdf_data = base64.b64encode(file.read()).decode('utf-8')
    
    # Send print request
    data = {
        "fileName": file_path.split('/')[-1],
        "pdfData": pdf_data
    }
    response = requests.post(f"{BASE_URL}/print", json=data)
    return response.json()

# Example usage
if __name__ == "__main__":
    # Check if agent is running
    status = check_status()
    print(f"Agent status: {status}")
    
    # List available printers
    printers = list_printers()
    print(f"Available printers: {printers}")
    
    # Print a PDF file
    if printers:
        result = print_pdf_file("document.pdf", printers[0])
        print(f"Print result: {result}")
```

---

## 🔒 Security Considerations

### CORS Policy
The API is configured with CORS to only accept requests from authorized Alpidi domains. Requests from other origins will be blocked.

### Local Access Only
By default, the service binds to localhost (127.0.0.1) and is not accessible from external networks. This provides security by limiting access to the local machine only.

### No Authentication
The API does not implement authentication as it's designed to run as a local service. In production environments, consider:
- Running behind a reverse proxy with authentication
- Implementing API key authentication
- Using network-level security (VPN, firewall rules)

### Input Validation
All endpoints perform input validation:
- PDF data is validated as proper Base64 encoding
- Printer names are validated against available printers
- Configuration values are sanitized

---

## 📈 Rate Limiting

Currently, no rate limiting is implemented. For production deployments, consider implementing rate limiting to prevent abuse:

```java
// Example rate limiting configuration
@Configuration
public class RateLimitConfig {
    @Bean
    public RedisRateLimiter redisRateLimiter() {
        return new RedisRateLimiter(10, 20); // 10 requests per second, burst of 20
    }
}
```

---

This API reference provides complete documentation for integrating with the Alpidi Printer Agent. For additional support or questions, refer to the main README.md file or contact the development team.
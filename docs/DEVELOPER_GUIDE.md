# Developer Guide

A comprehensive guide for developers working on the Alpidi Printer Agent project.

## 🚀 Getting Started

### Prerequisites

- **Java 17+**: Required for development and runtime
- **Maven 3.6+**: Build tool and dependency management
- **IDE**: IntelliJ IDEA, Eclipse, or VS Code with Java extensions
- **Git**: Version control

### Development Environment Setup

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd alpidi-printer-agent
   ```

2. **Import into IDE**
   - IntelliJ IDEA: Open the `pom.xml` file
   - Eclipse: Import as Maven project
   - VS Code: Open folder with Java Extension Pack

3. **Verify Setup**
   ```bash
   ./mvnw clean compile
   ./mvnw test
   ```

4. **Run the Application**
   ```bash
   ./mvnw spring-boot:run
   ```

## 🏗️ Project Architecture

### Package Structure

```
src/main/java/com/alpidiprinteragent/alpidiprinteragent/
├── AlpidiprinteragentApplication.java    # Main Spring Boot application
├── controller/                           # REST API layer
│   └── PrinterController.java
├── service/                             # Business logic layer
│   ├── PrinterService.java             # Core printer operations
│   ├── ConfigService.java              # Configuration management
│   └── PrinterSyncService.java         # Background synchronization
└── model/                               # Data models
    └── PrinterInfo.java
```

### Architectural Patterns

#### Layered Architecture
- **Controller Layer**: Handles HTTP requests and responses
- **Service Layer**: Contains business logic and operations
- **Model Layer**: Data transfer objects and entities

#### Dependency Injection
All components use Spring's dependency injection:
```java
@Service
public class PrinterService {
    // Business logic
}

@RestController
public class PrinterController {
    @Autowired
    private PrinterService printerService;
}
```

#### Configuration Management
External configuration through:
- `application.properties`
- Environment variables
- Command line arguments
- External configuration files

## 🔧 Development Workflow

### Code Style and Standards

#### Java Conventions
- Use camelCase for variables and methods
- Use PascalCase for classes
- Use UPPER_SNAKE_CASE for constants
- Follow Oracle Java naming conventions

#### Spring Boot Best Practices
```java
// Use constructor injection instead of field injection
@Service
public class PrinterService {
    private final ConfigService configService;
    
    public PrinterService(ConfigService configService) {
        this.configService = configService;
    }
}

// Use @Value for configuration properties
@Value("${backend.base-url}")
private String backendBaseUrl;

// Use proper exception handling
@PostMapping("/print")
public ResponseEntity<?> print(@RequestBody Map<String, String> body) {
    try {
        // Business logic
        return ResponseEntity.ok(result);
    } catch (Exception e) {
        log.error("Print operation failed", e);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(createErrorResponse(e.getMessage()));
    }
}
```

### Testing Strategy

#### Unit Tests
```java
@ExtendWith(MockitoExtension.class)
class PrinterServiceTest {
    
    @Mock
    private ConfigService configService;
    
    @InjectMocks
    private PrinterService printerService;
    
    @Test
    void shouldReturnAvailablePrinters() {
        // Given
        // When
        List<String> printers = printerService.getPrinters();
        
        // Then
        assertThat(printers).isNotEmpty();
    }
}
```

#### Integration Tests
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class PrinterControllerIntegrationTest {
    
    @Autowired
    private TestRestTemplate restTemplate;
    
    @Test
    void shouldReturnHealthStatus() {
        // When
        ResponseEntity<Map> response = restTemplate.getForEntity("/i-am-here", Map.class);
        
        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().get("status")).isEqualTo(true);
    }
}
```

#### Test Coverage
```bash
# Run tests with coverage
./mvnw test jacoco:report

# View coverage report
open target/site/jacoco/index.html
```

### Building and Packaging

#### Development Build
```bash
# Compile only
./mvnw compile

# Run tests
./mvnw test

# Package without tests
./mvnw package -DskipTests

# Clean and package
./mvnw clean package
```

#### Platform-Specific Builds
```bash
# Windows executable
./mvnw package -Pwindows

# macOS app bundle
./mvnw package -Pmac

# Linux packages
./mvnw package -Plinux

# Native image (GraalVM)
./mvnw package -Pnative
```

## 🔍 Debugging

### IDE Debugging

#### IntelliJ IDEA
1. Set breakpoints in your code
2. Run in debug mode: `Run > Debug 'AlpidiprinteragentApplication'`
3. Use the debugger to step through code

#### VS Code
1. Install Java Extension Pack
2. Set breakpoints
3. Press F5 to start debugging

### Remote Debugging
```bash
# Start application with debug port
java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005 -jar target/alpidiprinteragent-*-exec.jar

# Connect IDE to port 5005
```

### Logging Configuration

#### Development Logging
```properties
# application-dev.properties
logging.level.com.alpidiprinteragent=DEBUG
logging.level.org.springframework.web=DEBUG
logging.pattern.console=%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n
```

#### Custom Logger
```java
@Service
public class PrinterService {
    private static final Logger log = LoggerFactory.getLogger(PrinterService.class);
    
    public void printPdf(String printerName, byte[] pdfData) {
        log.debug("Printing PDF to printer: {}, size: {} bytes", printerName, pdfData.length);
        try {
            // Print logic
            log.info("Successfully printed to {}", printerName);
        } catch (Exception e) {
            log.error("Failed to print to {}: {}", printerName, e.getMessage(), e);
            throw e;
        }
    }
}
```

## 🧪 Testing

### Test Categories

#### Unit Tests
- Test individual components in isolation
- Mock external dependencies
- Fast execution
- High coverage

```java
@Test
void shouldThrowExceptionWhenPrinterNotFound() {
    // Given
    String nonExistentPrinter = "NonExistent Printer";
    byte[] pdfData = "test".getBytes();
    
    // When & Then
    assertThatThrownBy(() -> printerService.printPdf(nonExistentPrinter, pdfData))
        .isInstanceOf(Exception.class)
        .hasMessageContaining("Printer not found");
}
```

#### Integration Tests
- Test component interactions
- Use real Spring context
- Test HTTP endpoints

```java
@Test
void shouldSetActivePrinter() {
    // Given
    Map<String, String> request = Map.of(
        "printerName", "Test Printer",
        "productionPartnerUserId", "123"
    );
    
    // When
    ResponseEntity<Map> response = restTemplate.postForEntity(
        "/printers/active", request, Map.class);
    
    // Then
    assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    assertThat(response.getBody().get("status")).isEqualTo(true);
}
```

#### End-to-End Tests
- Test complete workflows
- Use real printers (if available)
- Simulate user interactions

### Test Data Management

#### Test Fixtures
```java
@TestConfiguration
public class TestConfig {
    
    @Bean
    @Primary
    public PrintService mockPrintService() {
        PrintService mockService = mock(PrintService.class);
        when(mockService.getName()).thenReturn("Test Printer");
        return mockService;
    }
}
```

#### Test Profiles
```properties
# application-test.properties
spring.profiles.active=test
backend.base-url=http://localhost:8080
logging.level.com.alpidiprinteragent=DEBUG
```

### Performance Testing

#### Load Testing with JMeter
```xml
<!-- printer-load-test.jmx -->
<TestPlan>
  <ThreadGroup>
    <HTTPSamplerProxy>
      <stringProp name="HTTPSampler.domain">localhost</stringProp>
      <stringProp name="HTTPSampler.port">9000</stringProp>
      <stringProp name="HTTPSampler.path">/printers</stringProp>
    </HTTPSamplerProxy>
  </ThreadGroup>
</TestPlan>
```

#### Benchmark Testing
```java
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
public class PrinterServiceBenchmark {
    
    @Benchmark
    public void benchmarkGetPrinters() {
        printerService.getPrinters();
    }
}
```

## 🔧 Configuration Management

### Property Sources

#### Application Properties
```properties
# application.properties
spring.application.name=alpidiprinteragent
server.port=9000
backend.base-url=http://localhost:8080

# Custom properties
app.printer.default-timeout=30000
app.sync.enabled=true
app.sync.cron=0 0 7 * * ?
```

#### Environment-Specific Configuration
```properties
# application-dev.properties
backend.base-url=http://localhost:8080
logging.level.com.alpidiprinteragent=DEBUG

# application-prod.properties
backend.base-url=https://api.alpidi.com
logging.level.com.alpidiprinteragent=INFO
```

#### Configuration Classes
```java
@ConfigurationProperties(prefix = "app.printer")
@Data
public class PrinterProperties {
    private int defaultTimeout = 30000;
    private boolean autoDetect = true;
    private String defaultPrinter;
}

@Configuration
@EnableConfigurationProperties(PrinterProperties.class)
public class AppConfig {
    // Configuration beans
}
```

### External Configuration

#### Command Line Arguments
```bash
java -jar alpidi-printer-agent.jar --server.port=9001 --backend.base-url=https://api.alpidi.com
```

#### Environment Variables
```bash
export SERVER_PORT=9001
export BACKEND_BASE_URL=https://api.alpidi.com
java -jar alpidi-printer-agent.jar
```

#### External Config Files
```bash
java -jar alpidi-printer-agent.jar --spring.config.location=file:./config/application.properties
```

## 🚀 Performance Optimization

### JVM Tuning

#### Memory Settings
```bash
# Production JVM settings
java -Xms512m -Xmx1024m \
     -XX:+UseG1GC \
     -XX:MaxGCPauseMillis=200 \
     -jar alpidi-printer-agent.jar
```

#### Monitoring JVM
```bash
# Enable JMX monitoring
java -Dcom.sun.management.jmxremote \
     -Dcom.sun.management.jmxremote.port=9999 \
     -Dcom.sun.management.jmxremote.authenticate=false \
     -Dcom.sun.management.jmxremote.ssl=false \
     -jar alpidi-printer-agent.jar
```

### Application Performance

#### Async Processing
```java
@Service
public class AsyncPrintService {
    
    @Async
    @EventListener
    public void handlePrintEvent(PrintEvent event) {
        // Async print processing
    }
}
```

#### Caching
```java
@Service
public class PrinterService {
    
    @Cacheable("printers")
    public List<String> getPrinters() {
        // Expensive printer discovery
        return Arrays.stream(PrintServiceLookup.lookupPrintServices(null, null))
            .map(PrintService::getName)
            .collect(Collectors.toList());
    }
}
```

#### Connection Pooling
```java
@Configuration
public class HttpClientConfig {
    
    @Bean
    public RestTemplate restTemplate() {
        HttpComponentsClientHttpRequestFactory factory = 
            new HttpComponentsClientHttpRequestFactory();
        factory.setConnectTimeout(5000);
        factory.setReadTimeout(10000);
        return new RestTemplate(factory);
    }
}
```

## 🔒 Security

### Input Validation

#### Request Validation
```java
@PostMapping("/print")
public ResponseEntity<?> print(@Valid @RequestBody PrintRequest request) {
    // Validated request processing
}

@Data
public class PrintRequest {
    @NotBlank(message = "PDF data is required")
    @Pattern(regexp = "^[A-Za-z0-9+/]*={0,2}$", message = "Invalid Base64 format")
    private String pdfData;
    
    @Size(max = 255, message = "Filename too long")
    private String fileName;
}
```

#### Sanitization
```java
public class SecurityUtils {
    
    public static String sanitizeFilename(String filename) {
        if (filename == null) return "document.pdf";
        return filename.replaceAll("[^a-zA-Z0-9.-]", "_");
    }
    
    public static boolean isValidBase64(String data) {
        try {
            Base64.getDecoder().decode(data);
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }
}
```

### Error Handling

#### Global Exception Handler
```java
@ControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ErrorResponse> handleIllegalArgument(IllegalArgumentException e) {
        ErrorResponse error = new ErrorResponse("INVALID_ARGUMENT", e.getMessage());
        return ResponseEntity.badRequest().body(error);
    }
    
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneral(Exception e) {
        log.error("Unexpected error", e);
        ErrorResponse error = new ErrorResponse("INTERNAL_ERROR", "An unexpected error occurred");
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
    }
}
```

## 📊 Monitoring and Observability

### Health Checks

#### Custom Health Indicators
```java
@Component
public class PrinterHealthIndicator implements HealthIndicator {
    
    @Override
    public Health health() {
        try {
            List<String> printers = printerService.getPrinters();
            return Health.up()
                .withDetail("printerCount", printers.size())
                .withDetail("printers", printers)
                .build();
        } catch (Exception e) {
            return Health.down()
                .withDetail("error", e.getMessage())
                .build();
        }
    }
}
```

### Metrics

#### Custom Metrics
```java
@Service
public class PrinterService {
    private final MeterRegistry meterRegistry;
    private final Counter printCounter;
    private final Timer printTimer;
    
    public PrinterService(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
        this.printCounter = Counter.builder("printer.print.count")
            .description("Number of print operations")
            .register(meterRegistry);
        this.printTimer = Timer.builder("printer.print.duration")
            .description("Print operation duration")
            .register(meterRegistry);
    }
    
    public void printPdf(String printerName, byte[] pdfData) {
        Timer.Sample sample = Timer.start(meterRegistry);
        try {
            // Print logic
            printCounter.increment();
        } finally {
            sample.stop(printTimer);
        }
    }
}
```

### Logging

#### Structured Logging
```java
@Service
public class PrinterService {
    private static final Logger log = LoggerFactory.getLogger(PrinterService.class);
    
    public void printPdf(String printerName, byte[] pdfData) {
        MDC.put("printer", printerName);
        MDC.put("documentSize", String.valueOf(pdfData.length));
        
        try {
            log.info("Starting print operation");
            // Print logic
            log.info("Print operation completed successfully");
        } catch (Exception e) {
            log.error("Print operation failed", e);
            throw e;
        } finally {
            MDC.clear();
        }
    }
}
```

## 🔄 CI/CD Pipeline

### GitHub Actions

#### Build and Test
```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
    
    - name: Cache Maven packages
      uses: actions/cache@v3
      with:
        path: ~/.m2
        key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
    
    - name: Run tests
      run: ./mvnw clean test
    
    - name: Generate test report
      uses: dorny/test-reporter@v1
      if: success() || failure()
      with:
        name: Maven Tests
        path: target/surefire-reports/*.xml
        reporter: java-junit
```

#### Multi-Platform Build
```yaml
# .github/workflows/build.yml
name: Build

on:
  release:
    types: [created]

jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    
    runs-on: ${{ matrix.os }}
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
    
    - name: Build application
      run: ./mvnw clean package -DskipTests
    
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: alpidi-printer-agent-${{ matrix.os }}
        path: target/*.jar
```

### Quality Gates

#### SonarQube Integration
```xml
<!-- pom.xml -->
<plugin>
    <groupId>org.sonarsource.scanner.maven</groupId>
    <artifactId>sonar-maven-plugin</artifactId>
    <version>3.9.1.2184</version>
</plugin>
```

```bash
# Run SonarQube analysis
./mvnw clean verify sonar:sonar \
  -Dsonar.projectKey=alpidi-printer-agent \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=your-token
```

## 🐛 Troubleshooting

### Common Development Issues

#### Port Already in Use
```bash
# Find process using port 9000
lsof -i :9000  # macOS/Linux
netstat -ano | findstr :9000  # Windows

# Kill the process
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

#### Maven Build Issues
```bash
# Clean Maven cache
./mvnw dependency:purge-local-repository

# Force update dependencies
./mvnw clean compile -U

# Skip tests if failing
./mvnw clean package -DskipTests
```

#### IDE Issues
```bash
# Reimport Maven project
# IntelliJ: File > Reload Maven Projects
# Eclipse: Right-click project > Maven > Reload Projects

# Clear IDE caches
# IntelliJ: File > Invalidate Caches and Restart
```

### Debugging Tips

#### Enable Debug Logging
```properties
logging.level.com.alpidiprinteragent=DEBUG
logging.level.org.springframework.web=DEBUG
logging.level.javax.print=DEBUG
```

#### Print System Information
```java
@PostConstruct
public void printSystemInfo() {
    log.info("Java version: {}", System.getProperty("java.version"));
    log.info("OS: {} {}", System.getProperty("os.name"), System.getProperty("os.version"));
    log.info("Available printers: {}", Arrays.toString(PrintServiceLookup.lookupPrintServices(null, null)));
}
```

#### Network Debugging
```bash
# Test API endpoints
curl -v http://localhost:9000/i-am-here
curl -v http://localhost:9000/printers

# Check network connectivity
telnet localhost 9000
```

## 📚 Additional Resources

### Documentation
- [Spring Boot Reference](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Java Print API](https://docs.oracle.com/javase/8/docs/technotes/guides/jps/)
- [Maven Documentation](https://maven.apache.org/guides/)

### Tools
- [IntelliJ IDEA](https://www.jetbrains.com/idea/)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Postman](https://www.postman.com/) - API testing
- [JMeter](https://jmeter.apache.org/) - Performance testing

### Best Practices
- [Spring Boot Best Practices](https://springframework.guru/spring-boot-best-practices/)
- [Java Coding Standards](https://google.github.io/styleguide/javaguide.html)
- [REST API Design](https://restfulapi.net/)

---

This developer guide provides comprehensive information for working on the Alpidi Printer Agent. For specific questions or issues, consult the project documentation or reach out to the development team.
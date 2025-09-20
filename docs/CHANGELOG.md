# Changelog

All notable changes to the Alpidi Printer Agent project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Released]

### Added
- Comprehensive English documentation
- API reference documentation
- Developer guide
- Deployment guide

### Changed
- Improved project structure documentation
- Enhanced build scripts with better error handling

### Fixed
- Documentation consistency across all files

## [0.0.1-SNAPSHOT] - 2025-09-19

### Added
- Initial release of Alpidi Printer Agent
- Spring Boot 3.5.5 application framework
- Java 24 support with modern language features
- RESTful API for printer management
- Cross-platform printer discovery and management
- PDF printing capabilities with Base64 encoding
- CORS support for multiple Alpidi domains
- File-based configuration storage (`printer-config.json`)
- Background synchronization service with Alpidi backend
- Multi-platform build support (Windows, macOS, Linux)

#### Core Features
- **Health Check Endpoint** (`/i-am-here`)
  - Agent status verification
  - Timestamp information
  
- **Printer Discovery** (`/printers`, `/printers-details`)
  - Automatic system printer detection
  - Detailed printer information including location and attributes
  - Support for network and local printers
  
- **Printer Management** (`/printers/active`)
  - Set active printer for print operations
  - User ID association for backend synchronization
  - Configuration persistence
  
- **Print Operations** (`/print`)
  - Base64-encoded PDF document printing
  - File name support for logging
  - Comprehensive error handling and validation
  - Document size tracking
  
- **Configuration Management** (`/config/*`)
  - Get current configuration
  - Update print settings (copies, orientation, paper size, quality)
  - Reset configuration to defaults
  - JSON-based configuration storage

#### Background Services
- **Printer Synchronization Service**
  - Daily synchronization at 7:00 AM (America/New_York)
  - Automatic printer configuration sync with backend
  - Error handling and logging

#### Cross-Platform Support
- **Windows**
  - Standard executable (`.exe`) with Launch4j
  - Portable version with auto-installation
  - Silent installer with system tray integration
  - Windows service support
  - NSIS-based installers

- **macOS**
  - Native application bundle (`.app`)
  - Professional DMG installer
  - Menu bar integration
  - LaunchAgent support for auto-start
  - macOS-specific UI handling

- **Linux**
  - DEB packages for Debian/Ubuntu
  - RPM packages for Red Hat/CentOS
  - Systemd service integration
  - Desktop file for application menu
  - Shell scripts for manual installation

#### Build System
- Maven-based build with multiple profiles
- Platform-specific build scripts
- Automated packaging for all platforms
- GraalVM native image support
- Docker containerization support

#### API Features
- **CORS Configuration**
  - Support for localhost development
  - Production Alpidi domains
  - Test and staging environments
  
- **Error Handling**
  - Comprehensive error responses
  - Structured error codes
  - Detailed error messages
  - HTTP status code compliance
  
- **Input Validation**
  - Base64 PDF data validation
  - Printer name validation
  - Configuration parameter validation
  - Security-focused input sanitization

#### Configuration
- **Application Properties**
  - Server port configuration (default: 9000)
  - Backend URL configuration
  - Logging level configuration
  - Banner mode disabled for cleaner startup
  
- **Runtime Configuration**
  - JSON-based configuration file
  - Active printer persistence
  - Print settings storage
  - User ID association
  - Timestamp tracking

#### Development Features
- **Spring Boot Integration**
  - Auto-configuration
  - Embedded Tomcat server
  - Actuator endpoints (optional)
  - Profile-based configuration
  
- **Java Print API Integration**
  - System printer discovery
  - Print job management
  - Printer attribute detection
  - Cross-platform printing support
  
- **Scheduling Support**
  - Cron-based background tasks
  - Timezone-aware scheduling
  - Error handling for scheduled tasks

#### Security Features
- **Local-only Access**
  - Localhost binding by default
  - No external network exposure
  
- **Input Validation**
  - Base64 encoding validation
  - File name sanitization
  - Parameter validation
  
- **Error Information**
  - Secure error messages
  - No sensitive information exposure
  - Structured error responses

#### Documentation
- **Build Instructions**
  - Platform-specific build guides
  - Deployment strategies
  - User experience optimization
  
- **API Documentation**
  - Endpoint specifications
  - Request/response examples
  - Error code reference
  
- **Configuration Guide**
  - Property configuration
  - Environment variables
  - External configuration files

### Technical Specifications
- **Java Version**: 24 (with backward compatibility to Java 17)
- **Spring Boot Version**: 3.5.5
- **Maven Version**: 3.6+
- **Default Port**: 9000
- **Configuration File**: `printer-config.json`
- **Log Level**: ERROR (Spring framework), configurable for application

### Dependencies
- `spring-boot-starter-web`: Web layer with embedded Tomcat
- `spring-boot-starter-test`: Testing framework with JUnit 5
- Java Print API (`javax.print`): System printer integration
- Jackson: JSON processing for configuration
- Launch4j: Windows executable generation
- JDEB: Debian package creation
- RPM Maven Plugin: Red Hat package creation

### Build Profiles
- **Default**: Standard JAR build
- **Windows**: Windows executable with Launch4j
- **Mac**: macOS application bundle with custom icon
- **Linux**: DEB and RPM package generation
- **Native**: GraalVM native image compilation

### Supported Platforms
- **Windows**: 10, 11 (x64)
- **macOS**: 10.15+ (Intel and Apple Silicon)
- **Linux**: Ubuntu 18.04+, CentOS 7+, Debian 9+

### Known Limitations
- Requires local printer drivers to be installed
- PDF printing only (no direct document format support)
- Single active printer at a time
- Local network access only by default

### Migration Notes
- This is the initial release, no migration required
- Configuration file will be created automatically on first run
- Default port 9000 - ensure no conflicts with existing services

---

## Version History Format

### [1.0.0] - 20225-09-19

#### Added
- New features and capabilities

#### Changed
- Changes to existing functionality

#### Deprecated
- Features that will be removed in future versions

#### Removed
- Features that have been removed

#### Fixed
- Bug fixes and corrections

#### Security
- Security-related changes and fixes

---

## Release Notes Template

When creating new releases, use this template:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- Feature description with technical details
- API endpoint additions
- New configuration options

### Changed
- Modified behavior descriptions
- Updated dependencies
- Performance improvements

### Fixed
- Bug fix descriptions
- Issue references (#123)
- Security vulnerability fixes

### Technical Details
- Java version requirements
- Dependency updates
- Breaking changes (if any)

### Migration Guide
- Steps required for upgrading
- Configuration changes needed
- Compatibility notes
```

---

## Contributing to Changelog

When contributing to the project:

1. **Add entries to [Unreleased]** section for new changes
2. **Use present tense** ("Add feature" not "Added feature")
3. **Reference issue numbers** when applicable
4. **Group similar changes** under appropriate categories
5. **Include breaking changes** with migration instructions
6. **Update version numbers** following semantic versioning

### Semantic Versioning Guidelines

- **MAJOR** (X.0.0): Breaking changes, major new features
- **MINOR** (0.X.0): New features, backward compatible
- **PATCH** (0.0.X): Bug fixes, backward compatible

### Change Categories

- **Added**: New features, endpoints, capabilities
- **Changed**: Modifications to existing functionality
- **Deprecated**: Features marked for future removal
- **Removed**: Features that have been removed
- **Fixed**: Bug fixes and corrections
- **Security**: Security-related changes

---

This changelog will be updated with each release to track the evolution of the Alpidi Printer Agent project.
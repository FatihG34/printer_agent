#!/bin/bash

echo "🐧 Building Self-Contained Alpidi Printer Agent for Linux..."
echo ""

# Check if Java is available for building
if ! command -v java >/dev/null 2>&1; then
    echo "❌ Java is required for building (but not for end users)!"
    echo "Please install Java 17+ for development"
    exit 1
fi

# Clean and build the project
echo "📦 Building JAR..."
./mvnw clean package -DskipTests

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Create distribution directory
mkdir -p dist/linux-bundled

echo ""
echo "🔧 Creating self-contained Linux application..."

# Create custom JRE using jlink
echo "📦 Creating minimal JRE for Linux..."
jlink --add-modules java.base,java.desktop,java.logging,java.management,java.naming,java.net.http,java.security.jgss,java.sql,java.xml,jdk.crypto.ec,jdk.localedata,jdk.zipfs \
      --output dist/linux-bundled/jre \
      --no-header-files \
      --no-man-pages \
      --strip-debug \
      --compress=2

if [ $? -ne 0 ]; then
    echo "⚠️  jlink failed, creating portable package instead..."
    BUNDLED_JRE=false
else
    echo "✅ Custom JRE created successfully!"
    BUNDLED_JRE=true
fi

# Create application structure
mkdir -p dist/linux-bundled/{bin,lib,share/applications,share/systemd}

# Copy JAR
cp target/alpidiprinteragent-*-exec.jar dist/linux-bundled/lib/alpidi-printer-agent.jar

# Create launcher script
if [ "$BUNDLED_JRE" = true ]; then
    # Launcher with bundled JRE
    cat > dist/linux-bundled/bin/alpidi-printer-agent << 'EOF'
#!/bin/bash

# Alpidi Printer Agent Launcher Script (Self-Contained)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
JAR_PATH="$APP_DIR/lib/alpidi-printer-agent.jar"
JAVA_CMD="$APP_DIR/jre/bin/java"

# Check if bundled JRE exists
if [ ! -f "$JAVA_CMD" ]; then
    echo "❌ Bundled Java Runtime not found!"
    echo "Please reinstall the application or contact support."
    exit 1
fi

# Check if JAR exists
if [ ! -f "$JAR_PATH" ]; then
    echo "❌ Application JAR not found at $JAR_PATH"
    echo "Please reinstall the application."
    exit 1
fi

# Create log directory
LOG_DIR="$HOME/.local/share/alpidi-printer-agent/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/alpidi-printer-agent.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_message "Starting Alpidi Printer Agent (Self-Contained)..."
log_message "Java Command: $JAVA_CMD"
log_message "JAR Path: $JAR_PATH"

# Check if already running
PID_FILE="$HOME/.local/share/alpidi-printer-agent/alpidi-printer-agent.pid"
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Alpidi Printer Agent is already running (PID: $PID)"
        log_message "Already running (PID: $PID)"
        exit 0
    else
        rm -f "$PID_FILE"
    fi
fi

# Determine run mode
RUN_MODE="desktop"
for arg in "$@"; do
    if [ "$arg" = "--headless" ] || [ "$arg" = "--service" ] || [ "$arg" = "--daemon" ]; then
        RUN_MODE="headless"
        break
    fi
done

# Check if running in desktop environment
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    RUN_MODE="headless"
fi

# Start the application
echo "Starting Alpidi Printer Agent (Self-Contained)..."
echo "Web interface will be available at: http://localhost:9000"

if [ "$RUN_MODE" = "headless" ] || [ ! -t 1 ]; then
    # Running in background/headless mode
    echo "Starting in headless mode..."
    nohup "$JAVA_CMD" -Djava.awt.headless=true -jar "$JAR_PATH" --headless "$@" >> "$LOG_FILE" 2>&1 &
    PID=$!
    echo $PID > "$PID_FILE"
    log_message "Started in headless mode (PID: $PID)"
    echo "Alpidi Printer Agent started in background (PID: $PID)"
    echo "Log file: $LOG_FILE"
else
    # Running in terminal with desktop support
    echo "Starting in desktop mode..."
    exec "$JAVA_CMD" -jar "$JAR_PATH" "$@"
fi
EOF
else
    # Launcher that looks for system Java
    cat > dist/linux-bundled/bin/alpidi-printer-agent << 'EOF'
#!/bin/bash

# Alpidi Printer Agent Launcher Script (Requires System Java)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
JAR_PATH="$APP_DIR/lib/alpidi-printer-agent.jar"

# Function to find Java
find_java() {
    # Check common Java locations
    for java_path in \
        "/usr/lib/jvm/java-17-openjdk/bin/java" \
        "/usr/lib/jvm/java-17-openjdk-amd64/bin/java" \
        "/usr/lib/jvm/java-21-openjdk/bin/java" \
        "/usr/lib/jvm/java-21-openjdk-amd64/bin/java" \
        "/usr/lib/jvm/default-java/bin/java" \
        "/usr/bin/java" \
        "/bin/java"; do
        if [ -x "$java_path" ]; then
            echo "$java_path"
            return 0
        fi
    done
    
    # Try which command
    if command -v java >/dev/null 2>&1; then
        echo "java"
        return 0
    fi
    
    return 1
}

# Find Java executable
JAVA_CMD=$(find_java)
if [ $? -ne 0 ]; then
    echo "❌ Java 17 or higher is required but not found."
    echo ""
    echo "Please install Java 17+:"
    echo "  Ubuntu/Debian: sudo apt install openjdk-17-jre"
    echo "  Fedora/RHEL:   sudo dnf install java-17-openjdk"
    echo "  Arch Linux:    sudo pacman -S jre17-openjdk"
    echo ""
    echo "Or download from: https://adoptium.net/"
    exit 1
fi

# Check Java version
JAVA_VERSION=$("$JAVA_CMD" -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$JAVA_VERSION" -lt 17 ] 2>/dev/null; then
    echo "❌ Java 17 or higher is required. Found Java $JAVA_VERSION"
    echo "Please upgrade your Java installation."
    exit 1
fi

# Check if JAR exists
if [ ! -f "$JAR_PATH" ]; then
    echo "❌ Application JAR not found at $JAR_PATH"
    exit 1
fi

# Create log directory
LOG_DIR="$HOME/.local/share/alpidi-printer-agent/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/alpidi-printer-agent.log"

# Start the application
echo "Starting Alpidi Printer Agent..."
echo "Web interface will be available at: http://localhost:9000"

# Determine run mode
RUN_MODE="desktop"
for arg in "$@"; do
    if [ "$arg" = "--headless" ] || [ "$arg" = "--service" ] || [ "$arg" = "--daemon" ]; then
        RUN_MODE="headless"
        break
    fi
done

if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    RUN_MODE="headless"
fi

if [ "$RUN_MODE" = "headless" ] || [ ! -t 1 ]; then
    echo "Starting in headless mode..."
    nohup "$JAVA_CMD" -Djava.awt.headless=true -jar "$JAR_PATH" --headless "$@" >> "$LOG_FILE" 2>&1 &
    echo "Started in background. Log file: $LOG_FILE"
else
    echo "Starting in desktop mode..."
    exec "$JAVA_CMD" -jar "$JAR_PATH" "$@"
fi
EOF
fi

# Make launcher executable
chmod +x dist/linux-bundled/bin/alpidi-printer-agent

# Create desktop entry
cat > dist/linux-bundled/share/applications/alpidi-printer-agent.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Alpidi Printer Agent
GenericName=Printer Management Service
Comment=Local printer management service for Alpidi applications (Self-Contained)
Exec=alpidi-printer-agent
Icon=printer
Terminal=false
StartupNotify=true
Categories=Office;Printing;System;
Keywords=printer;print;alpidi;agent;service;
MimeType=application/pdf;
X-GNOME-Autostart-enabled=true
X-Desktop-File-Install-Version=0.26
EOF

# Create systemd service
cat > dist/linux-bundled/share/systemd/alpidi-printer-agent.service << 'EOF'
[Unit]
Description=Alpidi Printer Agent (Self-Contained)
Documentation=https://alpidi.com/docs/printer-agent
After=network.target
Wants=network.target

[Service]
Type=simple
User=alpidi-printer-agent
Group=alpidi-printer-agent
ExecStart=/opt/alpidi-printer-agent/bin/alpidi-printer-agent --headless
ExecStop=/bin/kill -TERM $MAINPID
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=alpidi-printer-agent

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/alpidi-printer-agent

# Environment
Environment=JAVA_OPTS=-Djava.awt.headless=true
Environment=SERVER_PORT=9000

[Install]
WantedBy=multi-user.target
EOF

# Create installation script
cat > dist/linux-bundled/install.sh << 'EOF'
#!/bin/bash
echo "Installing Alpidi Printer Agent (Self-Contained)..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

INSTALL_DIR="/opt/alpidi-printer-agent"

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Copy files
cp -r bin lib "$INSTALL_DIR/"
if [ -d "jre" ]; then
    cp -r jre "$INSTALL_DIR/"
    echo "✅ Bundled Java Runtime installed"
fi

# Copy desktop entry
cp share/applications/alpidi-printer-agent.desktop /usr/share/applications/

# Copy systemd service
cp share/systemd/alpidi-printer-agent.service /etc/systemd/system/

# Create symlink for global access
ln -sf "$INSTALL_DIR/bin/alpidi-printer-agent" /usr/local/bin/alpidi-printer-agent

# Set permissions
chmod +x "$INSTALL_DIR/bin/alpidi-printer-agent"
chmod 644 /usr/share/applications/alpidi-printer-agent.desktop
chmod 644 /etc/systemd/system/alpidi-printer-agent.service

# Create user and group for service
if ! getent group alpidi-printer-agent >/dev/null; then
    addgroup --system alpidi-printer-agent
fi

if ! getent passwd alpidi-printer-agent >/dev/null; then
    adduser --system --ingroup alpidi-printer-agent \
            --home /var/lib/alpidi-printer-agent \
            --no-create-home \
            --gecos "Alpidi Printer Agent" \
            --shell /bin/false \
            alpidi-printer-agent
fi

# Create directories
mkdir -p /var/log/alpidi-printer-agent
mkdir -p /var/lib/alpidi-printer-agent

# Set ownership
chown -R alpidi-printer-agent:alpidi-printer-agent /var/log/alpidi-printer-agent
chown -R alpidi-printer-agent:alpidi-printer-agent /var/lib/alpidi-printer-agent

# Reload systemd
systemctl daemon-reload
systemctl enable alpidi-printer-agent.service

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q /usr/share/applications
fi

echo ""
echo "✅ Installation completed!"
echo ""
echo "Start service: sudo systemctl start alpidi-printer-agent"
echo "Check status:  sudo systemctl status alpidi-printer-agent"
echo "View logs:     sudo journalctl -u alpidi-printer-agent -f"
echo "Web interface: http://localhost:9000"
echo ""
if [ -d "$INSTALL_DIR/jre" ]; then
    echo "🎯 No Java installation required - bundled JRE included!"
else
    echo "📋 Requires Java 17+ on target system"
fi
EOF

chmod +x dist/linux-bundled/install.sh

# Create README
cat > dist/linux-bundled/README.txt << 'EOF'
Alpidi Printer Agent - Self-Contained Linux Package

INSTALLATION:
1. Extract this package: tar -xzf alpidi-printer-agent-*.tar.gz
2. Run installation script: sudo ./install.sh
3. Start the service: sudo systemctl start alpidi-printer-agent

MANUAL INSTALLATION:
1. Copy files to /opt/alpidi-printer-agent/
2. Create symlink: sudo ln -s /opt/alpidi-printer-agent/bin/alpidi-printer-agent /usr/local/bin/
3. Run: alpidi-printer-agent

FEATURES:
• Self-contained (no Java installation required)
• Systemd service integration
• Desktop application entry
• Web interface: http://localhost:9000

SUPPORT:
https://alpidi.com/support
EOF

# Create TAR.GZ package
echo "📦 Creating TAR.GZ package..."
cd dist
tar -czf "AlpidiPrinterAgent-Linux-SelfContained.tar.gz" linux-bundled/
cd ..

echo ""
echo "========================================"
echo "✅ SELF-CONTAINED LINUX BUILD COMPLETED!"
echo "========================================"
echo ""
echo "📁 Generated files:"
echo ""

if [ "$BUNDLED_JRE" = true ]; then
    echo "✅ Self-contained package with bundled JRE:"
    echo "   📁 dist/linux-bundled/ (folder)"
    echo "   📦 dist/AlpidiPrinterAgent-Linux-SelfContained.tar.gz"
    echo ""
    echo "🎯 DISTRIBUTION: Users can run without installing Java!"
    echo "   • Extract package"
    echo "   • Run: sudo ./install.sh"
    echo "   • No Java installation required"
else
    echo "⚠️  Portable package (requires Java on target machine):"
    echo "   📁 dist/linux-bundled/ (folder)"
    echo "   📦 dist/AlpidiPrinterAgent-Linux-SelfContained.tar.gz"
    echo ""
    echo "📋 Users need Java 17+ installed on their machine"
fi

echo ""
echo "🌐 Application will be available at: http://localhost:9000"

# Show package size
echo ""
echo "📊 Package Size:"
ls -lh "dist/AlpidiPrinterAgent-Linux-SelfContained.tar.gz"
#!/bin/bash

echo "🐧 Building Alpidi Printer Agent for Linux Distributions..."
echo ""

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)
echo "🖥️  Detected Linux Distribution: $DISTRO"
echo ""

# Functions for package creation
create_manual_rpm() {
    echo "⚠️  Manual RPM creation requires rpmbuild tools"
    echo "    Install: sudo dnf install rpm-build rpmdevtools"
    echo "    Or: sudo yum install rpm-build rpmdevtools"
}

create_appimage() {
    echo "Creating AppImage structure..."
    
    APPDIR="dist/linux/appimage/AlpidiPrinterAgent.AppDir"
    mkdir -p "$APPDIR/usr/bin"
    mkdir -p "$APPDIR/usr/share/applications"
    mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
    
    # Copy application files
    cp target/alpidiprinteragent-*-exec.jar "$APPDIR/usr/bin/alpidi-printer-agent.jar"
    cp src/linux/alpidi-printer-agent.desktop "$APPDIR/"
    cp src/linux/alpidi-printer-agent.desktop "$APPDIR/usr/share/applications/"
    
    # Create AppRun script
    cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/usr/bin"
exec java -jar alpidi-printer-agent.jar "$@"
EOF
    chmod +x "$APPDIR/AppRun"
    
    # Copy icon if available
    if [ -f "src/main/resources/icon.png" ]; then
        cp src/main/resources/icon.png "$APPDIR/alpidi-printer-agent.png"
        cp src/main/resources/icon.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/"
    fi
    
    # Try to create AppImage if appimagetool is available
    if command -v appimagetool >/dev/null 2>&1; then
        appimagetool "$APPDIR" "dist/linux/appimage/AlpidiPrinterAgent-1.0.0-x86_64.AppImage"
        echo "✅ AppImage created successfully!"
    else
        echo "⚠️  appimagetool not available, AppImage directory created only"
        echo "    Download appimagetool from: https://appimage.github.io/appimagetool/"
    fi
}

create_generic_package() {
    echo "Creating generic TAR.GZ package..."
    
    GENERIC_DIR="dist/linux/generic/alpidi-printer-agent-1.0.0"
    mkdir -p "$GENERIC_DIR/bin"
    mkdir -p "$GENERIC_DIR/lib"
    mkdir -p "$GENERIC_DIR/share/applications"
    mkdir -p "$GENERIC_DIR/share/systemd"
    
    # Copy files
    cp target/alpidiprinteragent-*-exec.jar "$GENERIC_DIR/lib/alpidi-printer-agent.jar"
    cp src/linux/alpidi-printer-agent "$GENERIC_DIR/bin/"
    cp src/linux/alpidi-printer-agent.desktop "$GENERIC_DIR/share/applications/"
    cp src/linux/alpidi-printer-agent.service "$GENERIC_DIR/share/systemd/"
    
    # Create installation script
    cat > "$GENERIC_DIR/install.sh" << 'EOF'
#!/bin/bash
echo "Installing Alpidi Printer Agent..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Create directories
mkdir -p /opt/alpidi-printer-agent

# Copy files
cp lib/alpidi-printer-agent.jar /opt/alpidi-printer-agent/
cp bin/alpidi-printer-agent /usr/bin/
cp share/applications/alpidi-printer-agent.desktop /usr/share/applications/
cp share/systemd/alpidi-printer-agent.service /etc/systemd/system/

# Set permissions
chmod 755 /usr/bin/alpidi-printer-agent
chmod 644 /usr/share/applications/alpidi-printer-agent.desktop
chmod 644 /etc/systemd/system/alpidi-printer-agent.service

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable alpidi-printer-agent.service

echo "Installation completed!"
echo "Start service: sudo systemctl start alpidi-printer-agent"
echo "Web interface: http://localhost:9000"
EOF
    chmod +x "$GENERIC_DIR/install.sh"
    
    # Create README
    cat > "$GENERIC_DIR/README.txt" << 'EOF'
Alpidi Printer Agent - Generic Linux Package

INSTALLATION:
1. Extract this package: tar -xzf alpidi-printer-agent-*.tar.gz
2. Run installation script: sudo ./install.sh
3. Start the service: sudo systemctl start alpidi-printer-agent

MANUAL INSTALLATION:
1. Copy alpidi-printer-agent.jar to /opt/alpidi-printer-agent/
2. Copy alpidi-printer-agent script to /usr/bin/
3. Make it executable: chmod +x /usr/bin/alpidi-printer-agent
4. Run: alpidi-printer-agent

REQUIREMENTS:
- Java 17 or higher
- Linux with systemd (for service mode)

WEB INTERFACE:
http://localhost:9000

SUPPORT:
https://alpidi.com/support
EOF
    
    # Create TAR.GZ
    cd dist/linux/generic
    tar -czf "alpidi-printer-agent-1.0.0-linux.tar.gz" "alpidi-printer-agent-1.0.0"
    rm -rf "alpidi-printer-agent-1.0.0"
    cd - > /dev/null
    
    echo "✅ Generic TAR.GZ package created!"
}

# Clean and build the base JAR
echo "📦 Building base JAR..."
./mvnw clean package -DskipTests

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Base JAR build successful!"
echo ""

# Create distribution directories
mkdir -p dist/linux/{deb,rpm,appimage,generic}

# Copy base JAR for all formats
cp target/alpidiprinteragent-*-exec.jar dist/linux/generic/alpidi-printer-agent.jar

# Make scripts executable
chmod +x src/linux/alpidi-printer-agent
chmod +x src/deb/control/postinst
chmod +x src/deb/control/prerm  
chmod +x src/deb/control/postrm

echo "🔧 Building Linux packages..."

# Build DEB package (Debian/Ubuntu)
echo "📦 Building DEB package for Debian/Ubuntu..."
if command -v dpkg-deb >/dev/null 2>&1 || ./mvnw -q jdeb:jdeb -Plinux 2>/dev/null; then
    if [ -f target/*.deb ]; then
        cp target/*.deb dist/linux/deb/
        echo "✅ DEB package created successfully!"
    else
        echo "⚠️  DEB package creation failed, creating manual package..."
        create_manual_deb
    fi
else
    echo "⚠️  DEB tools not available, creating manual package..."
    create_manual_deb
fi

# Build RPM package (Red Hat/Fedora)
echo "📦 Building RPM package for Red Hat/Fedora..."
if command -v rpmbuild >/dev/null 2>&1; then
    ./mvnw -q rpm:rpm -Plinux 2>/dev/null || create_manual_rpm
    if [ -f target/rpm/*/RPMS/*/*.rpm ]; then
        cp target/rpm/*/RPMS/*/*.rpm dist/linux/rpm/
        echo "✅ RPM package created successfully!"
    else
        create_manual_rpm
    fi
else
    echo "⚠️  RPM tools not available, skipping RPM creation"
    echo "    Install rpm-build package on Linux to create RPM packages"
fi

# Create AppImage (Universal Linux)
echo "📦 Creating AppImage (Universal Linux)..."
create_appimage

# Create generic TAR.GZ package
echo "📦 Creating generic TAR.GZ package..."
create_generic_package

echo ""
echo "========================================"
echo "🎉 LINUX BUILD COMPLETED SUCCESSFULLY!"
echo "========================================"
echo ""
echo "📁 Generated packages in 'dist/linux/':"
echo ""

# Show created packages
if [ -f dist/linux/deb/*.deb ]; then
    echo "📦 DEB Package (Debian/Ubuntu):"
    ls -lh dist/linux/deb/*.deb
    echo "   Install: sudo dpkg -i alpidi-printer-agent_*.deb"
    echo "   Install deps: sudo apt-get install -f"
    echo ""
fi

if [ -f dist/linux/rpm/*.rpm ]; then
    echo "📦 RPM Package (Red Hat/Fedora/CentOS):"
    ls -lh dist/linux/rpm/*.rpm
    echo "   Install: sudo rpm -ivh alpidi-printer-agent-*.rpm"
    echo "   Or: sudo dnf install alpidi-printer-agent-*.rpm"
    echo ""
fi

if [ -f dist/linux/appimage/*.AppImage ]; then
    echo "📦 AppImage (Universal Linux):"
    ls -lh dist/linux/appimage/*.AppImage
    echo "   Run: chmod +x *.AppImage && ./AlpidiPrinterAgent-*.AppImage"
    echo ""
fi

if [ -f dist/linux/generic/*.tar.gz ]; then
    echo "📦 Generic Package (All Linux):"
    ls -lh dist/linux/generic/*.tar.gz
    echo "   Extract: tar -xzf alpidi-printer-agent-*.tar.gz"
    echo "   Run: ./alpidi-printer-agent/bin/alpidi-printer-agent"
    echo ""
fi

echo "🐧 Linux Features:"
echo "   • Systemd service integration"
echo "   • Desktop application entry"
echo "   • Automatic startup support"
echo "   • System user/group creation"
echo "   • Log rotation support"
echo "   • Web Interface: http://localhost:9000"
echo ""
echo "📋 Distribution Support:"
echo "   • Ubuntu/Debian: .deb package"
echo "   • Fedora/RHEL/CentOS: .rpm package"  
echo "   • Universal Linux: .AppImage"
echo "   • Any Linux: .tar.gz package"
echo ""
echo "🎯 Ready for Linux distribution!"


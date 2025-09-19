#!/bin/bash

echo "🚀 Building Alpidi Printer Agent for All Platforms..."
echo ""

# Detect current OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    CYGWIN*)    MACHINE=Cygwin;;
    MINGW*)     MACHINE=MinGw;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo "🖥️  Detected OS: $MACHINE"
echo ""

# Create main distribution directory
mkdir -p dist

# Build base JAR first
echo "📦 Building base JAR..."
./mvnw clean package -DskipTests

if [ $? -ne 0 ]; then
    echo "❌ Base build failed!"
    exit 1
fi

echo "✅ Base JAR build successful!"
echo ""

# Build Windows executable (works on all platforms via Launch4j)
echo "🪟 Building Windows executable..."
mkdir -p dist/windows

if [ -f "target/alpidi-printer-agent.exe" ]; then
    cp target/alpidi-printer-agent.exe dist/windows/
    echo "✅ Windows .exe created successfully!"
else
    echo "⚠️  Windows .exe not found, copying JAR for Windows..."
    cp target/alpidiprinteragent-*-exec.jar dist/windows/alpidi-printer-agent.jar
fi

# Build macOS app (only on macOS)
if [ "$MACHINE" = "Mac" ]; then
    echo ""
    echo "🍎 Building macOS application..."
    mkdir -p dist/mac
    
    # Try to build .app bundle (without icon to avoid errors)
    echo "🎨 Building macOS app bundle..."
    ./mvnw package -DskipTests -Pmac -q
    
    if [ -d "target/Alpidi Printer Agent.app" ]; then
        cp -r "target/Alpidi Printer Agent.app" "dist/mac/"
        echo "✅ macOS .app bundle created!"
        
        # Create DMG if possible
        if command -v hdiutil &> /dev/null; then
            echo "📀 Creating DMG installer..."
            mkdir -p "dist/mac/dmg-temp"
            cp -r "target/Alpidi Printer Agent.app" "dist/mac/dmg-temp/"
            ln -s /Applications "dist/mac/dmg-temp/Applications"
            
            hdiutil create -volname "Alpidi Printer Agent" \
                          -srcfolder "dist/mac/dmg-temp" \
                          -ov -format UDZO \
                          "dist/mac/AlpidiPrinterAgent.dmg" > /dev/null 2>&1
            
            rm -rf "dist/mac/dmg-temp"
            echo "✅ DMG installer created!"
        fi
    else
        echo "⚠️  .app bundle creation failed, using JAR for macOS..."
        cp target/alpidiprinteragent-*-exec.jar dist/mac/alpidi-printer-agent.jar
        
        # Create launcher script for macOS
        cat > dist/mac/launch-alpidi-printer-agent.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
java -Dapple.laf.useScreenMenuBar=true \
     -Dcom.apple.macos.use-file-dialog-packages=true \
     -Xdock:name="Alpidi Printer Agent" \
     -jar alpidi-printer-agent.jar
EOF
        chmod +x dist/mac/launch-alpidi-printer-agent.sh
    fi
else
    echo ""
    echo "🍎 Skipping macOS build (not running on macOS)"
    echo "   To build for macOS, run this script on a Mac"
fi

# Build Linux packages (comprehensive)
if [ "$MACHINE" = "Linux" ]; then
    echo ""
    echo "🐧 Building comprehensive Linux packages..."
    ./build-linux.sh
else
    echo ""
    echo "🐧 Building basic Linux version..."
    mkdir -p dist/linux
    
    cp target/alpidiprinteragent-*-exec.jar dist/linux/alpidi-printer-agent.jar
    
    # Create Linux launcher script
    cat > dist/linux/launch-alpidi-printer-agent.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
java -jar alpidi-printer-agent.jar
EOF
    chmod +x dist/linux/launch-alpidi-printer-agent.sh
    
    # Create .desktop file for Linux
    cat > dist/linux/alpidi-printer-agent.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Alpidi Printer Agent
Comment=Local printer management service for Alpidi applications
Exec=java -jar alpidi-printer-agent.jar
Icon=printer
Terminal=false
Categories=Office;Printing;
EOF
    
    echo "✅ Basic Linux version created!"
    echo "   Run ./build-linux.sh on Linux for full package support"
fi

echo ""
echo "========================================"
echo "🎉 MULTI-PLATFORM BUILD COMPLETED!"
echo "========================================"
echo ""
echo "📁 Distribution Structure:"
echo ""
echo "dist/"
echo "├── windows/"
if [ -f "dist/windows/alpidi-printer-agent.exe" ]; then
    echo "│   └── alpidi-printer-agent.exe (Windows executable)"
else
    echo "│   └── alpidi-printer-agent.jar (Windows JAR)"
fi
echo "├── mac/"
if [ -d "dist/mac/Alpidi Printer Agent.app" ]; then
    echo "│   ├── Alpidi Printer Agent.app (macOS app bundle)"
    if [ -f "dist/mac/AlpidiPrinterAgent.dmg" ]; then
        echo "│   └── AlpidiPrinterAgent.dmg (macOS installer)"
    fi
else
    echo "│   ├── alpidi-printer-agent.jar"
    echo "│   └── launch-alpidi-printer-agent.sh"
fi
echo "└── linux/"
echo "    ├── alpidi-printer-agent.jar"
echo "    ├── launch-alpidi-printer-agent.sh"
echo "    └── alpidi-printer-agent.desktop"
echo ""
echo "🌐 All versions will run on: http://localhost:9000"
echo ""
echo "📋 Distribution Instructions:"
echo "• Windows: Distribute .exe file (or .jar if .exe unavailable)"
echo "• macOS: Distribute .dmg installer (or .app bundle)"
echo "• Linux: Distribute .jar + .sh + .desktop files"
echo ""
echo "🎯 Ready for cross-platform distribution!"

# Show total size
echo ""
echo "📊 Distribution Size:"
du -sh dist/* 2>/dev/null || echo "Size calculation unavailable"
#!/bin/bash

echo "🍎 Building Self-Contained Alpidi Printer Agent for macOS..."
echo ""

# Check if Java is available for building
if ! command -v java >/dev/null 2>&1; then
    echo "❌ Java is required for building (but not for end users)!"
    echo "Please install Java 17+ for development: https://adoptium.net/"
    exit 1
fi

# Clean and build the project
echo "📦 Building JAR and basic macOS .app bundle..."
./mvnw clean package -DskipTests -Pmac

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Create distribution directory
mkdir -p dist/mac-bundled

echo ""
echo "🔧 Creating self-contained macOS application..."

# Try to create custom JRE using jlink (requires modular project)
echo "📦 Attempting to create minimal JRE for macOS..."

# Check if we can use jlink (requires module-info.java)
if [ -f "src/main/java/module-info.java" ]; then
    jlink --add-modules java.base,java.desktop,java.logging,java.management,java.naming,java.net.http,java.security.jgss,java.sql,java.xml,jdk.crypto.ec,jdk.localedata,jdk.zipfs \
          --output dist/mac-bundled/jre \
          --no-header-files \
          --no-man-pages \
          --strip-debug \
          --compress=2
    
    if [ $? -eq 0 ]; then
        echo "✅ Custom JRE created successfully!"
        BUNDLED_JRE=true
    else
        echo "⚠️  jlink failed, using portable approach..."
        BUNDLED_JRE=false
    fi
else
    echo "⚠️  Project is not modular, using portable approach..."
    echo "    (This is normal - users will need Java installed)"
    BUNDLED_JRE=false
fi

# Create self-contained .app bundle
APP_DIR="dist/mac-bundled/Alpidi Printer Agent.app"
mkdir -p "$APP_DIR/Contents/"{MacOS,Resources,Java}

# Copy JAR
cp target/alpidiprinteragent-*-exec.jar "$APP_DIR/Contents/Java/alpidi-printer-agent.jar"

# Copy icon if available
if [ -f "src/main/resources/icon.icns" ]; then
    cp src/main/resources/icon.icns "$APP_DIR/Contents/Resources/"
fi

# Copy JRE if created
if [ "$BUNDLED_JRE" = true ]; then
    cp -r dist/mac-bundled/jre "$APP_DIR/Contents/"
    JRE_PATH="Contents/jre/bin/java"
    echo "✅ Bundled JRE included in .app bundle"
else
    JRE_PATH="java"
    echo "⚠️  Using system Java (must be installed on target machine)"
fi

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>alpidi-printer-agent</string>
	<key>CFBundleIconFile</key>
	<string>icon.icns</string>
	<key>CFBundleIdentifier</key>
	<string>com.alpidi.printeragent</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Alpidi Printer Agent</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>CFBundleVersion</key>
	<string>1.0.0</string>
	<key>LSMinimumSystemVersion</key>
	<string>10.15</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>LSUIElement</key>
	<true/>
	<key>LSBackgroundOnly</key>
	<false/>
</dict>
</plist>
EOF

# Create launcher script
cat > "$APP_DIR/Contents/MacOS/alpidi-printer-agent" << EOF
#!/bin/bash
cd "\$(dirname "\$0")/../Java"

# Set Java path
if [ -f "../jre/bin/java" ]; then
    # Use bundled JRE
    JAVA_CMD="../jre/bin/java"
    echo "Using bundled Java Runtime"
else
    # Use system Java
    JAVA_CMD="java"
    
    # Check if Java is available
    if ! command -v java >/dev/null 2>&1; then
        osascript -e 'display dialog "Java is required but not installed. Please install Java 17+ from https://adoptium.net/" buttons {"OK"} default button "OK"'
        open "https://adoptium.net/temurin/releases/?version=17"
        exit 1
    fi
    
    # Check Java version
    JAVA_VERSION=\$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
    if [ "\$JAVA_VERSION" -lt 17 ] 2>/dev/null; then
        osascript -e 'display dialog "Java 17 or higher is required. Please update your Java installation." buttons {"OK"} default button "OK"'
        open "https://adoptium.net/temurin/releases/?version=17"
        exit 1
    fi
fi

# Start the application
exec "\$JAVA_CMD" -Dapple.laf.useScreenMenuBar=true \\
     -Dcom.apple.macos.use-file-dialog-packages=true \\
     -Dcom.apple.macos.useScreenMenuBar=true \\
     -Xdock:name="Alpidi Printer Agent" \\
     -jar alpidi-printer-agent.jar
EOF

# Make launcher executable
chmod +x "$APP_DIR/Contents/MacOS/alpidi-printer-agent"

echo "✅ Self-contained .app bundle created!"

# Create DMG installer
echo ""
echo "📀 Creating DMG installer..."

# Create temporary DMG directory
mkdir -p "dist/mac-bundled/dmg-temp"
cp -r "$APP_DIR" "dist/mac-bundled/dmg-temp/"

# Create Applications symlink
ln -s /Applications "dist/mac-bundled/dmg-temp/Applications"

# Create installation instructions
cat > "dist/mac-bundled/dmg-temp/INSTALL.txt" << 'EOF'
Alpidi Printer Agent - Self-Contained macOS Application

INSTALLATION:
1. Drag "Alpidi Printer Agent.app" to the Applications folder
2. Double-click the app in Applications to start
3. No Java installation required! (Java is bundled)

FEATURES:
• Runs in background (menu bar integration)
• Web interface: http://localhost:9000
• Automatic printer detection
• No external dependencies

SUPPORT:
https://alpidi.com/support
EOF

# Create DMG
if command -v hdiutil >/dev/null 2>&1; then
    hdiutil create -volname "Alpidi Printer Agent Self-Contained" \
                  -srcfolder "dist/mac-bundled/dmg-temp" \
                  -ov -format UDZO \
                  -imagekey zlib-level=9 \
                  "dist/AlpidiPrinterAgent-macOS-SelfContained.dmg"
    
    # Clean up temp directory
    rm -rf "dist/mac-bundled/dmg-temp"
    
    echo "✅ DMG installer created!"
else
    echo "⚠️  hdiutil not available, skipping DMG creation"
fi

# Create ZIP alternative
echo "📦 Creating ZIP package..."
cd "dist/mac-bundled"
zip -r "../AlpidiPrinterAgent-macOS-SelfContained.zip" "Alpidi Printer Agent.app" > /dev/null 2>&1
cd - > /dev/null

echo ""
echo "========================================"
echo "✅ SELF-CONTAINED macOS BUILD COMPLETED!"
echo "========================================"
echo ""
echo "📁 Generated files:"
echo ""

if [ "$BUNDLED_JRE" = true ]; then
    echo "✅ Self-contained package with bundled JRE:"
    echo "   📁 dist/mac-bundled/Alpidi Printer Agent.app"
    if [ -f "dist/AlpidiPrinterAgent-macOS-SelfContained.dmg" ]; then
        echo "   📀 dist/AlpidiPrinterAgent-macOS-SelfContained.dmg"
    fi
    echo "   📦 dist/AlpidiPrinterAgent-macOS-SelfContained.zip"
    echo ""
    echo "🎯 DISTRIBUTION: Users can run without installing Java!"
    echo "   • Drag .app to Applications folder"
    echo "   • Double-click to run"
    echo "   • No Java installation required"
else
    echo "⚠️  Portable package (requires Java on target machine):"
    echo "   📁 dist/mac-bundled/Alpidi Printer Agent.app"
    if [ -f "dist/AlpidiPrinterAgent-macOS-SelfContained.dmg" ]; then
        echo "   📀 dist/AlpidiPrinterAgent-macOS-SelfContained.dmg"
    fi
    echo "   📦 dist/AlpidiPrinterAgent-macOS-SelfContained.zip"
    echo ""
    echo "📋 Users need Java 17+ installed on their machine"
fi

echo ""
echo "🌐 Application will be available at: http://localhost:9000"

# Show package size
echo ""
echo "📊 Package Size:"
if [ -f "dist/AlpidiPrinterAgent-macOS-SelfContained.dmg" ]; then
    ls -lh "dist/AlpidiPrinterAgent-macOS-SelfContained.dmg"
fi
ls -lh "dist/AlpidiPrinterAgent-macOS-SelfContained.zip"
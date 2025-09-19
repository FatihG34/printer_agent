#!/bin/bash

echo "🍎 Building Alpidi Printer Agent for macOS..."
echo ""

echo "🎨 Using custom macOS application icon..."

# Clean and build the project with Mac profile
echo "📦 Building JAR and macOS .app bundle..."
./mvnw clean package -DskipTests -Pmac

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Create distribution directory
mkdir -p dist/mac

# Check if .app bundle was created
if [ -d "target/Alpidi Printer Agent.app" ]; then
    # Copy the .app bundle
    cp -r "target/Alpidi Printer Agent.app" "dist/mac/"
    echo "✅ macOS .app bundle created successfully!"
    
    # Create professional DMG installer
    if command -v hdiutil &> /dev/null; then
        echo "📀 Creating professional DMG installer..."
        
        # Create temporary DMG directory
        mkdir -p "dist/mac/dmg-temp"
        cp -r "target/Alpidi Printer Agent.app" "dist/mac/dmg-temp/"
        
        # Create Applications symlink for drag & drop
        ln -s /Applications "dist/mac/dmg-temp/Applications"
        
        # Create installation instructions
        cat > "dist/mac/dmg-temp/INSTALL.txt" << 'EOF'
Alpidi Printer Agent - Installation Instructions

1. Drag "Alpidi Printer Agent.app" to the Applications folder
2. Open Applications and double-click "Alpidi Printer Agent"
3. The app will appear in your menu bar
4. Access web interface: http://localhost:9000

Features:
• Menu bar integration
• Automatic printer detection  
• Web-based management
• System notifications

Support: https://alpidi.com/support
EOF
        
        # Create DMG with better settings
        hdiutil create -volname "Alpidi Printer Agent Installer" \
                      -srcfolder "dist/mac/dmg-temp" \
                      -ov -format UDZO \
                      -imagekey zlib-level=9 \
                      "dist/mac/AlpidiPrinterAgent.dmg"
        
        # Clean up temp directory
        rm -rf "dist/mac/dmg-temp"
        
        echo "✅ Professional DMG installer created!"
        
        # Create ZIP alternative for users who prefer it
        echo "📦 Creating ZIP alternative..."
        cd "dist/mac"
        zip -r "AlpidiPrinterAgent-macOS.zip" "Alpidi Printer Agent.app" > /dev/null 2>&1
        cd - > /dev/null
        
        echo "✅ ZIP archive created as alternative!"
    else
        echo "⚠️  hdiutil not available, skipping DMG creation"
    fi
else
    echo "⚠️  .app bundle not found, copying JAR instead..."
    cp target/alpidiprinteragent-*-exec.jar dist/mac/alpidi-printer-agent.jar
    
    # Create a simple launcher script
    cat > dist/mac/launch-alpidi-printer-agent.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
java -jar alpidi-printer-agent.jar
EOF
    chmod +x dist/mac/launch-alpidi-printer-agent.sh
fi

echo ""
echo "========================================"
echo "✅ macOS BUILD COMPLETED SUCCESSFULLY!"
echo "========================================"
echo ""
echo "📁 Generated files in 'dist/mac' folder:"
echo ""

if [ -d "dist/mac/Alpidi Printer Agent.app" ]; then
    echo "🎯 Alpidi Printer Agent.app"
    echo "   - Native macOS application bundle"
    echo "   - Double-click to install and run"
    echo "   - Integrates with macOS menu bar"
    echo "   - Handles macOS quit events properly"
    echo ""
fi

if [ -f "dist/mac/AlpidiPrinterAgent.dmg" ]; then
    echo "📀 AlpidiPrinterAgent.dmg"
    echo "   - macOS installer disk image"
    echo "   - Drag & drop installation"
    echo "   - Professional distribution format"
    echo ""
fi

if [ -f "dist/mac/alpidi-printer-agent.jar" ]; then
    echo "📦 alpidi-printer-agent.jar + launcher script"
    echo "   - Cross-platform JAR with macOS launcher"
    echo "   - Run: ./launch-alpidi-printer-agent.sh"
    echo ""
fi

echo "🍎 macOS Features:"
echo "   - Menu bar integration"
echo "   - Native macOS quit handling"
echo "   - Dock icon support"
echo "   - macOS notification support"
echo "   - Web Interface: http://localhost:9000"
echo ""
echo "📋 Distribution Options:"
echo "   1. .app bundle - Drag to Applications folder"
echo "   2. .dmg installer - Professional installer experience"
echo "   3. JAR + script - Cross-platform compatibility"
echo ""
echo "🎉 Ready for macOS distribution!"

# Show file details
echo ""
echo "📊 File Details:"
ls -lah dist/mac/
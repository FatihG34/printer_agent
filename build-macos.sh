#!/bin/bash

echo "🚀 Building Alpidi Printer Agent on macOS for Windows distribution..."
echo ""

# Clean and build the project (skip native compilation)
echo "📦 Building JAR and Windows executable..."
./mvnw clean package -DskipTests

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Create distribution directory
mkdir -p dist

# Check if exe file was created
if [ -f "target/alpidi-printer-agent.exe" ]; then
    # Copy the generated exe file to distribution directory
    cp target/alpidi-printer-agent.exe dist/
    echo "✅ Windows executable created successfully!"
else
    echo "⚠️  .exe file not found, copying JAR instead..."
    cp target/alpidiprinteragent-*-exec.jar dist/alpidi-printer-agent.jar
fi

echo ""
echo "========================================"
echo "✅ BUILD COMPLETED SUCCESSFULLY!"
echo "========================================"
echo ""
echo "📁 Generated files in 'dist' folder:"
echo ""

if [ -f "dist/alpidi-printer-agent.exe" ]; then
    echo "🎯 alpidi-printer-agent.exe"
    echo "   - Windows executable (requires Java 17+)"
    echo "   - Built on macOS using Launch4j cross-compilation"
    echo "   - Ready for Windows distribution"
    echo "   - Users: Double-click to run"
else
    echo "📦 alpidi-printer-agent.jar"
    echo "   - Cross-platform JAR file"
    echo "   - Requires Java 17+ on target system"
    echo "   - Run with: java -jar alpidi-printer-agent.jar"
fi

echo ""
echo "🌐 Application Details:"
echo "   - Web Interface: http://localhost:9000"
echo "   - System Tray: Available on Windows"
echo "   - Auto-start: Configured for Windows"
echo ""
echo "📋 Distribution Notes:"
echo "   - Built on macOS for Windows compatibility"
echo "   - Launch4j handles Java detection on Windows"
echo "   - For advanced installers (NSIS), use Windows machine"
echo ""
echo "🎉 Ready for distribution!"

# Show file details
echo ""
echo "📊 File Details:"
ls -lh dist/
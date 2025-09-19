#!/bin/bash

echo "📱 Building Alpidi Printer Agent for Android..."
echo ""

# Check if Android SDK is available
if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
    echo "❌ Android SDK not found!"
    echo "Please install Android Studio and set ANDROID_HOME or ANDROID_SDK_ROOT"
    echo "Download from: https://developer.android.com/studio"
    exit 1
fi

# Set Android SDK path
ANDROID_SDK=${ANDROID_HOME:-$ANDROID_SDK_ROOT}
echo "🔧 Using Android SDK: $ANDROID_SDK"

# Check if Gradle wrapper exists
if [ ! -f "android-app/gradlew" ]; then
    echo "📦 Creating Gradle wrapper..."
    cd android-app
    
    # Create gradle wrapper
    cat > gradlew << 'EOF'
#!/bin/sh
exec gradle "$@"
EOF
    chmod +x gradlew
    
    # Create gradle wrapper properties
    mkdir -p gradle/wrapper
    cat > gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
    
    cd ..
fi

# Create missing resource files
echo "🎨 Creating Android resources..."

# Create strings.xml
mkdir -p android-app/app/src/main/res/values
cat > android-app/app/src/main/res/values/strings.xml << 'EOF'
<resources>
    <string name="app_name">Alpidi Printer Agent</string>
    <string name="start_service">Start Printer Agent</string>
    <string name="stop_service">Stop Printer Agent</string>
    <string name="web_interface">Open Web Interface</string>
    <string name="status_checking">Checking status...</string>
    <string name="status_running">Printer Agent is running</string>
    <string name="status_stopped">Printer Agent is stopped</string>
</resources>
EOF

# Create colors.xml
cat > android-app/app/src/main/res/values/colors.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="purple_200">#FFBB86FC</color>
    <color name="purple_500">#FF6200EE</color>
    <color name="purple_700">#FF3700B3</color>
    <color name="teal_200">#FF03DAC5</color>
    <color name="teal_700">#FF018786</color>
    <color name="black">#FF000000</color>
    <color name="white">#FFFFFFFF</color>
    <color name="alpidi_primary">#FF2196F3</color>
    <color name="alpidi_secondary">#FF4CAF50</color>
</resources>
EOF

# Create themes.xml
mkdir -p android-app/app/src/main/res/values-night
cat > android-app/app/src/main/res/values/themes.xml << 'EOF'
<resources xmlns:tools="http://schemas.android.com/tools">
    <style name="Theme.AlpidiPrinterAgent" parent="Theme.MaterialComponents.DayNight.DarkActionBar">
        <item name="colorPrimary">@color/alpidi_primary</item>
        <item name="colorPrimaryVariant">@color/purple_700</item>
        <item name="colorOnPrimary">@color/white</item>
        <item name="colorSecondary">@color/alpidi_secondary</item>
        <item name="colorSecondaryVariant">@color/teal_700</item>
        <item name="colorOnSecondary">@color/black</item>
        <item name="android:statusBarColor" tools:targetApi="l">?attr/colorPrimaryVariant</item>
    </style>
</resources>
EOF

# Create printer icon
mkdir -p android-app/app/src/main/res/drawable
cat > android-app/app/src/main/res/drawable/ic_printer.xml << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="?attr/colorOnSurface">
  <path
      android:fillColor="@android:color/white"
      android:pathData="M19,8H5c-1.66,0 -3,1.34 -3,3v6h4v4h12v-4h4v-6c0,-1.66 -1.34,-3 -3,-3zM16,19H8v-5h8v5zM19,12c-0.55,0 -1,-0.45 -1,-1s0.45,-1 1,-1 1,0.45 1,1 -0.45,1 -1,1zM18,3H6v4h12V3z"/>
</vector>
EOF

# Create launcher icons (basic)
mkdir -p android-app/app/src/main/res/mipmap-hdpi
mkdir -p android-app/app/src/main/res/mipmap-mdpi
mkdir -p android-app/app/src/main/res/mipmap-xhdpi
mkdir -p android-app/app/src/main/res/mipmap-xxhdpi
mkdir -p android-app/app/src/main/res/mipmap-xxxhdpi

# Copy printer icon as launcher icon (simplified)
cp android-app/app/src/main/res/drawable/ic_printer.xml android-app/app/src/main/res/mipmap-hdpi/ic_launcher.xml
cp android-app/app/src/main/res/drawable/ic_printer.xml android-app/app/src/main/res/mipmap-hdpi/ic_launcher_round.xml

# Create project-level build.gradle
cat > android-app/build.gradle << 'EOF'
buildscript {
    ext.kotlin_version = "1.9.10"
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.2'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

plugins {
    id 'com.android.application' version '8.1.2' apply false
    id 'org.jetbrains.kotlin.android' version '1.9.10' apply false
}
EOF

# Create settings.gradle
cat > android-app/settings.gradle << 'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "Alpidi Printer Agent"
include ':app'
EOF

# Create gradle.properties
cat > android-app/gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=true
kotlin.code.style=official
android.nonTransitiveRClass=true
EOF

# Build the Android app
echo "🔨 Building Android APK..."
cd android-app

# Clean and build
if command -v gradle >/dev/null 2>&1; then
    gradle clean assembleDebug
elif [ -f "./gradlew" ]; then
    ./gradlew clean assembleDebug
else
    echo "❌ Gradle not found!"
    echo "Please install Gradle or use Android Studio"
    exit 1
fi

cd ..

# Create distribution directory
mkdir -p dist/android

# Copy APK if build successful
if [ -f "android-app/app/build/outputs/apk/debug/app-debug.apk" ]; then
    cp android-app/app/build/outputs/apk/debug/app-debug.apk dist/android/AlpidiPrinterAgent-debug.apk
    echo "✅ Android APK created successfully!"
else
    echo "⚠️  APK not found, creating manual package..."
    
    # Create a simple APK structure for manual building
    mkdir -p dist/android/manual-build
    cp -r android-app/* dist/android/manual-build/
    
    cat > dist/android/BUILD_INSTRUCTIONS.txt << 'EOF'
Android Build Instructions

AUTOMATIC BUILD FAILED - MANUAL BUILD REQUIRED

1. Install Android Studio:
   https://developer.android.com/studio

2. Open the project:
   - Open Android Studio
   - Select "Open an existing project"
   - Navigate to: dist/android/manual-build/

3. Build the APK:
   - Click "Build" menu
   - Select "Build Bundle(s) / APK(s)"
   - Choose "Build APK(s)"

4. Find the APK:
   - Location: app/build/outputs/apk/debug/app-debug.apk

ALTERNATIVE - Command Line Build:
1. Set ANDROID_HOME environment variable
2. Run: cd dist/android/manual-build && ./gradlew assembleDebug

REQUIREMENTS:
- Android Studio or Android SDK
- Java 8 or higher
- Gradle 8.0+
EOF
fi

echo ""
echo "========================================"
echo "📱 ANDROID BUILD COMPLETED!"
echo "========================================"
echo ""
echo "📁 Generated files in 'dist/android/':"
echo ""

if [ -f "dist/android/AlpidiPrinterAgent-debug.apk" ]; then
    echo "📦 AlpidiPrinterAgent-debug.apk"
    ls -lh dist/android/AlpidiPrinterAgent-debug.apk
    echo "   Install: adb install AlpidiPrinterAgent-debug.apk"
    echo "   Or transfer to Android device and install manually"
    echo ""
fi

if [ -d "dist/android/manual-build" ]; then
    echo "📁 manual-build/ (Android Studio project)"
    echo "   Open with Android Studio for manual building"
    echo "   See: dist/android/BUILD_INSTRUCTIONS.txt"
    echo ""
fi

echo "📱 Android Features:"
echo "   • Native Android application"
echo "   • Foreground service for background operation"
echo "   • WebView integration for web interface"
echo "   • System notifications"
echo "   • Auto-start on boot (optional)"
echo "   • Material Design UI"
echo ""
echo "📋 Installation:"
echo "   1. Enable 'Unknown Sources' in Android settings"
echo "   2. Transfer APK to Android device"
echo "   3. Tap APK file to install"
echo "   4. Grant necessary permissions"
echo ""
echo "🎯 Ready for Android distribution!"

# Show file details
echo ""
echo "📊 File Details:"
ls -lah dist/android/
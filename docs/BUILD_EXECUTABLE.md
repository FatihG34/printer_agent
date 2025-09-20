# Alpidi Printer Agent – Executable/Paket Oluşturma Rehberi

Bu rehber, Spring Boot tabanlı `alpidiprinteragent` uygulamasının çalıştırılabilir dosyaya (executable) ve dağıtım paketlerine dönüştürülmesi için izlenen yöntemleri ve adımları ayrıntılı olarak açıklar. Tüm komutlar proje kök dizini `alpidiprinteragent/` içinden çalıştırılmalıdır.

## 1) Genel Bakış
- Uygulama çıktı tipi varsayılan olarak Spring Boot "fat jar" (yani bağımlılıkları barındıran `*-exec.jar`) üretir.
  - Kaynak: `pom.xml` içindeki `spring-boot-maven-plugin` → `classifier=exec`.
- Platforma özel executable ve paket formatları:
  - Windows
    - Launch4j ile `.exe`
    - JRE gömülü "self-contained" paket (zip klasör veya tek dosya varyantları)
    - NSIS ile Auto-installer ve Portable SFX
    - (Opsiyonel) GraalVM ile native tek dosya `.exe`
  - macOS
    - `maven-antrun-plugin` ile `.app` bundle (Mac profili)
    - DMG ve ZIP dağıtımları
    - (Opsiyonel) JRE gömülü self-contained `.app`
  - Linux
    - `jdeb` ile `.deb`, `rpm-maven-plugin` ile `.rpm`
    - AppImage ve generic `.tar.gz`
    - (Opsiyonel) JRE gömülü self-contained paket

Projedeki yardımcı scriptler, bu paketlerin üretimini otomatikleştirir. İlgili scriptler:
- `build-windows.bat`, `build-windows-bundled.bat`, `build-windows-single-exe.bat`, `build-windows-sfx.sh`, `build-windows-bundled-cross.sh`
- `build-mac.sh`, `build-mac-bundled.sh`, `build-macos.sh`
- `build-linux.sh`, `build-linux-bundled.sh`, `build-appimage.sh`
- (Native) `build-native-exe.sh`

## 2) Ön Koşullar
- Java 17+ ve Maven (geliştirici makinesinde)
- Windows özel:
  - Launch4j (PATH’te) – `.exe` üretimi için
  - NSIS (opsiyonel) – installer ve portable SFX üretimi için
- macOS özel:
  - `hdiutil` – DMG oluşturmak için
  - Kod imzalama/notarization için geliştirici sertifikaları (opsiyonel, üretim için önerilir)
- Linux özel:
  - `dpkg-deb` / `jdeb` ve/veya `rpmbuild` – deb/rpm üretimi için
  - `appimagetool` – AppImage üretimi için (opsiyonel)
  - `jlink` – self-contained JRE gömülü paketler için (opsiyonel)
- Native (opsiyonel):
  - GraalVM ve `native-image` aracı (`gu install native-image`)

## 3) Temel Jar (Fat Jar) Üretimi
- Komut:
```bash
./mvnw clean package -DskipTests
```
- Çıktı:
  - `target/alpidiprinteragent-0.0.1-SNAPSHOT-exec.jar`
- Çalıştırma:
```bash
java -jar target/alpidiprinteragent-0.0.1-SNAPSHOT-exec.jar
```
- Ana sınıf: `com.alpidiprinteragent.alpidiprinteragent.AlpidiprinteragentApplication`
  - Kaynak: `pom.xml` → `spring-boot-maven-plugin` `mainClass`

## 4) Windows – .exe ve Dağıtım Seçenekleri
### 4.1) Standart .exe (Launch4j)
- Nerede tanımlı: `pom.xml` → `launch4j-maven-plugin`
  - `jar` olarak `*-exec.jar`, `mainClass` olarak `service/PlatformServiceWrapper` kullanılır.
- Script ile üretim:
```bat
build-windows.bat
```
- Çıktılar: `dist/` altında
  - `alpidi-printer-agent.exe` (sistem Java 17+ gerektirir)
  - NSIS yüklüyse: `AlpidiPrinterAgentAutoInstaller.exe` (silent), `AlpidiPrinterAgent-Portable.exe` (portablesfx)

Neden `PlatformServiceWrapper`?
- `service/PlatformServiceWrapper.java`, OS tespiti yapıp ilgili wrapper’ı (`WindowsServiceWrapper`, `MacServiceWrapper`, `LinuxServiceWrapper`) çağırır.
- Windows’ta system tray, restart, exit gibi kullanıcı deneyimi sağlar.

### 4.2) JRE Gömülü Self-Contained Paket
- Script:
```bat
build-windows-bundled.bat
```
- Yaptığı işler:
  - `mvn package` ile jar ve `alpidi-printer-agent.exe` üretir.
  - `jlink` veya `win/jre-win64` hazır JRE ile `dist/windows-bundled/` içinde JRE’yi gömer.
  - Batch/PowerShell launcher ve (varsa) Launch4j ile JRE-bundled `.exe` çıkarır.
  - ZIP paket üretir: `dist/AlpidiPrinterAgent-Windows-SelfContained.zip`
- Kullanıcı hedefi: Java kurulumuna ihtiyaç duymadan çalıştırma.

### 4.3) Tek Dosya EXE (JRE gömülü)
- Script:
```bat
build-windows-single-exe.bat
```
- Gereksinim: `win/jre-win64` altında hazır JRE.
- Sonuç: `dist/windows-single-exe/AlpidiPrinterAgent-Standalone.exe`
  - Tek dosya, Java kurulumu gerekmez.

### 4.4) Self-Extracting EXE (SFX)
- Script (bash):
```bash
./build-windows-sfx.sh
```
- Yaptıkları: JAR + JRE → tek dosya self-extracting paket (7-Zip SFX veya PowerShell tabanlı alternatif).
- Çıktı: `dist/windows-sfx/AlpidiPrinterAgent-SelfExtracting.exe` (veya `.ps1`)

### 4.5) GraalVM Native EXE (Opsiyonel)
- `pom.xml` → `profiles/native` + `native-maven-plugin`
- Script:
```bash
./build-native-exe.sh
# veya
./mvnw clean package -Pnative
```
- Artılar: Çok hızlı açılış, düşük bellek, tek dosya, Java gerekmez.
- Dikkat: Spring Boot native imajında ek yansıtma/konfigürasyon gerekebilir.

## 5) macOS – .app, DMG ve Self-Contained
### 5.1) .app Bundle (Maven, mac profili)
- `pom.xml` → `profiles/mac` + `maven-antrun-plugin`
  - `.app` içerisine `*-exec.jar` kopyalanır.
  - `Contents/Info.plist` ve `Contents/MacOS/alpidi-printer-agent` launcher üretilir.
  - İkon: `src/main/resources/icon.icns` (varsa kopyalanır).
- Script:
```bash
./build-mac.sh
```
- Çıktılar: `dist/mac/`
  - `Alpidi Printer Agent.app`
  - `AlpidiPrinterAgent.dmg` (hdiutil mevcutsa)
  - `AlpidiPrinterAgent-macOS.zip`

### 5.2) Self-Contained macOS (JRE gömülü)
- Script:
```bash
./build-mac-bundled.sh
```
- Eğer proje modüler ise `jlink` ile minimal JRE oluşturur; değilse sistem Java gerektiren portable `.app` üretir.
- Çıktılar: `dist/mac-bundled/Alpidi Printer Agent.app`, DMG/ZIP

### 5.3) macOS Notları
- Kod imzalama ve notarization üretim dağıtımı için önerilir.
- `LSUIElement=true` ile menü çubuğu/arka plan uygulaması davranışı hedeflenmiştir.

## 6) Linux – DEB, RPM, AppImage, TAR.GZ ve Self-Contained
### 6.1) Paketler (Maven profili: linux)
- `pom.xml` içinde:
  - `jdeb` (DEB), `rpm-maven-plugin` (RPM)
  - Dosyalar: `src/linux/alpidi-printer-agent`, `.desktop`, `.service`
- Script:
```bash
./build-linux.sh
```
- Çıktılar: `dist/linux/` altında
  - `deb/` → `.deb`
  - `rpm/` → `.rpm`
  - `appimage/` → `.AppImage` (appimagetool varsa)
  - `generic/` → `.tar.gz` ve kurulum script’i

### 6.2) Self-Contained Linux (JRE gömülü)
- Script:
```bash
./build-linux-bundled.sh
```
- `jlink` ile minimal JRE oluşturur (başarısızlıkta portable mod)
- Çıktılar: `dist/linux-bundled/` klasörü ve `dist/AlpidiPrinterAgent-Linux-SelfContained.tar.gz`

### 6.3) AppImage (Alternatif)
- Script:
```bash
./build-appimage.sh
```
- Gerekli: `appimagetool` (PATH’te)

## 7) Giriş Noktaları ve Çalıştırma Modları
- Spring Boot ana uygulama: `AlpidiprinteragentApplication`
- Platform sarmalayıcı: `service/PlatformServiceWrapper`
  - OS tespiti yapar ve ilgili `WindowsServiceWrapper`, `MacServiceWrapper`, `LinuxServiceWrapper` sınıflarını çağırır.
  - Tray/menu bar, restart, exit gibi UX özelliklerini sağlar.
- macOS için menü çubuğu entegrasyonu, Linux için `DISPLAY` kontrolü ile headless/desktop seçimleri mevcuttur.

## 8) Özelleştirme Noktaları
- Port ve backend:
  - `src/main/resources/application.properties` → `server.port=9000`, `backend.base-url=...`
- İkonlar:
  - Windows: `win/icon.ico` (Launch4j configlerinde referans)
  - macOS: `src/main/resources/icon.icns`
  - Linux: AppImage/generic paketlerde `icon.png` (opsiyonel) ve `.desktop` girdisi
- Versiyon/adlandırma:
  - `pom.xml` → `<version>0.0.1-SNAPSHOT</version>`
  - Dağıtım isimleri scriptlerde sabitlenmiş olabilir; sürüm değişiminde gözden geçirin.

## 9) Doğrulama ve Test
- Çalıştırma sonrası sağlık kontrolü:
```bash
curl http://localhost:9000/i-am-here
```
- Yazıcı listesi:
```bash
curl http://localhost:9000/printers
```
- Windows:
  - `.exe` çalıştırıldığında system tray’de ikon ve web arayüzü (9000) kontrol edilir.
- macOS:
  - `.app` açıldığında menü çubuğunda menü ve 9000 portu kontrol edilir.
- Linux:
  - `.deb/.rpm` ile kurulum sonrası `systemctl status alpidi-printer-agent` ve `journalctl -u alpidi-printer-agent -f` logları.

## 10) İmzalama, Notarization ve Güvenlik (Öneriler)
- Windows kod imzalama: `.exe` ve installer dosyalarının SmartScreen/AV uyarılarını azaltır.
- macOS kod imzalama ve notarization: Gatekeeper engellerini önler.
- Linux paketleri: GPG imzaları ve depo entegrasyonu (opsiyonel)
- Firewall:
  - 9000/TCP yerel erişim; dağıtım ortamına göre kısıtlamaları ve HTTPS’yi değerlendirin.

## 11) Sık Kullanılan Komutlar (Özet)
- Fat Jar:
```bash
./mvnw clean package -DskipTests
```
- Windows (exe + installer’lar):
```bat
build-windows.bat
```
- Windows Self-Contained (klasör/zip):
```bat
build-windows-bundled.bat
```
- Windows Standalone Tek EXE:
```bat
build-windows-single-exe.bat
```
- Windows Self-Extracting Tek EXE:
```bash
./build-windows-sfx.sh
```
- macOS (.app, DMG, ZIP):
```bash
./build-mac.sh
```
- macOS Self-Contained (.app + JRE):
```bash
./build-mac-bundled.sh
```
- Linux (deb, rpm, appimage, tar.gz):
```bash
./build-linux.sh
```
- Linux Self-Contained (tar.gz + JRE):
```bash
./build-linux-bundled.sh
```
- Native (GraalVM):
```bash
./mvnw clean package -Pnative
# veya
./build-native-exe.sh
```

## 12) Sorun Giderme İpuçları
- Port 9000 kullanımda:
```bash
lsof -i :9000  # macOS/Linux
netstat -ano | findstr :9000  # Windows
```
- Java bulunamadı (portable paket değilse):
  - Kullanıcıya Java 17+ kurulum linki yönlendirilir (scriptler bunu yapar).
- Launch4j/NSIS yoksa:
  - Scriptler installer oluşturmayı atlar; temel `.exe` ve/veya JAR kopyalanır.
- Linux paket araçları yoksa:
  - Script alternatif (manual) paket oluşturmaya geçebilir veya adımları çıktıda açıklar.
- GraalVM native image sorunları:
  - `native-image` aracı ve build tool’ların kurulu olması gerekir; Spring yansıma konfigürasyonları gerekebilir (`native-config/`).

---
Bu doküman, `alpidiprinteragent` uygulamasını farklı platformlarda executable ve dağıtım paketlerine dönüştürmek için gereken yöntemleri ve karar noktalarını kapsar. Üretim dağıtımlarında kod imzalama, notarization ve güvenlik ayarlarını uygulamanız önerilir.

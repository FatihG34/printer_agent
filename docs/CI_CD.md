# CI/CD Rehberi – GitHub Actions

Bu doküman, projedeki GitHub Actions iş akışını (CI/CD) ayrıntılı olarak açıklar, mevcut kurulumdaki eksik/uyumsuz noktaları işaretler ve iyileştirme önerileriyle birlikte güncel bir örnek iş akışı sunar.

## 1) Mevcut İş Akışı: `.github/workflows/build-installers.yml`

Kaynak dosya: `.github/workflows/build-installers.yml`

Özet akış:
- **Tetikleyiciler**
  - `push` (sadece `main` dalı)
  - `workflow_dispatch` (elle tetikleme)
- **Matrix build**
  - `os: [ubuntu-latest, windows-latest, macos-latest]`
- **Adımlar**
  - `actions/checkout@v4`
  - `actions/setup-java@v4` ile Java 21 (Temurin)
  - Maven cache (`~/.m2`) – `actions/cache@v4`
  - `mvn clean package -DskipTests`
  - Linux/macOS için bazı scriptlere `chmod +x`
  - `jpackage` ile platforma özel paket oluşturma denemeleri (deb/pkg/msi)
  - `actions/upload-artifact@v4` ile çıktıların yüklenmesi

Koddan alıntı (özet):
```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest, macos-latest]

- uses: actions/setup-java@v4
  with:
    distribution: temurin
    java-version: 21

- run: mvn clean package -DskipTests

# jpackage ile paketleme (platforma göre)
- run: jpackage ... --type deb ...      # Ubuntu
- run: jpackage ... --type pkg ...      # macOS
- run: jpackage ... --type msi ...      # Windows
```

### 1.1) Mevcut Dosyadaki Uyumsuzluklar
- `--main-jar agent-0.0.1-SNAPSHOT.jar` ve `--main-class com.company.agent.MainApplication` proje ile uyumlu değil.
  - Bu projede üretilen jar: `target/alpidiprinteragent-0.0.1-SNAPSHOT-exec.jar`
  - Ana sınıf: `com.alpidiprinteragent.alpidiprinteragent.AlpidiprinteragentApplication` (veya dağıtım senaryosuna göre `service/PlatformServiceWrapper`)
- `--resource-dir installer/...` gibi dizinler repoda bulunmuyor (Linux/macos/windows altı). Bu dizinler yoksa `jpackage` adımları başarısız olur.
- Projede zaten çok sayıda platform özel build scripti ve Maven plugin’i var (`launch4j`, `jdeb`, `rpm-maven-plugin`, `maven-antrun-plugin`). `jpackage` yerine mevcut stratejilerle hizalanmak daha doğru olabilir.

## 2) Önerilen Yaklaşım ve Strateji
Mevcut proje, Maven ve script tabanlı bir paketleme modeli kullanıyor. CI/CD'de bu akışı otomatikleştirmek en az sürprizle sonuç verir.

- **Jar üretimi**: `./mvnw clean package -DskipTests`
- **Windows**: `build-windows.bat` (Launch4j + NSIS), alternatif olarak `build-windows-bundled.bat` / `build-windows-single-exe.bat` / `build-windows-sfx.sh`
- **macOS**: `build-mac.sh` (Mac profili ile .app + DMG/ZIP), alternatif `build-mac-bundled.sh`
- **Linux**: `build-linux.sh` (.deb/.rpm/AppImage/tar.gz), alternatif `build-linux-bundled.sh`
- **Native (opsiyonel)**: `./mvnw -Pnative package` veya `build-native-exe.sh`

Bu sayede:
- Plugin ve scriptlerde tanımlı yol/isimler ile tutarlılık korunur.
- `jpackage` için ek kaynak klasörleri oluşturmaya gerek kalmaz.

## 3) Örnek: Çoklu Platform CI İş Akışı
Aşağıdaki örnek, mevcut scriptleri kullanarak artefakt üreten bir iş akışıdır. `main` dalına push ve elle tetikleme ile çalışır.

```yaml
ame: Build Distributions

on:
  push:
    branches: ["main"]
  workflow_dispatch:

jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "21"
          cache: maven

      - name: Build base JAR (all OS)
        run: |
          ./mvnw -version
          ./mvnw clean package -DskipTests

      - name: Build Windows installers
        if: runner.os == 'Windows'
        shell: cmd
        run: |
          build-windows.bat
          build-windows-bundled.bat
          build-windows-single-exe.bat

      - name: Build macOS bundles
        if: runner.os == 'macOS'
        run: |
          chmod +x build-mac.sh build-mac-bundled.sh || true
          ./build-mac.sh
          ./build-mac-bundled.sh

      - name: Build Linux packages
        if: runner.os == 'Linux'
        run: |
          chmod +x build-linux.sh build-linux-bundled.sh || true
          ./build-linux.sh
          ./build-linux-bundled.sh

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: alpidi-printer-agent-${{ matrix.os }}
          path: |
            dist/**
            target/*.jar
```

Notlar:
- `actions/setup-java@v4` üzerinde `cache: maven` kullanıldığı için ek `actions/cache` adımı gereksizdir.
- Windows tarafında `shell: cmd` ile `.bat` scriptleri çağrılır.
- macOS/Linux tarafında `.sh` scriptleri çalıştırmadan önce `chmod +x` güvenliği eklenmiştir.

## 4) Sürümleme ve Release Otomasyonu (Öneri)
Bir release açıldığında artefaktların otomatik olarak GitHub Releases’a yüklenmesi için ek bir iş akışı önerisi:

```yaml
ame: Release

on:
  push:
    tags:
      - 'v*.*.*'
  workflow_dispatch:

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '21'
          cache: maven

      - run: ./mvnw clean package -DskipTests

      - name: Build linux/mac packages
        run: |
          chmod +x build-linux.sh build-mac.sh || true
          ./build-linux.sh
          ./build-mac.sh

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: |
            dist/**
            target/*.jar
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 5) Güvenlik ve Sırlar
- Özel depolar, imzalama sertifikaları veya 3P servis anahtarları gerekiyorsa GitHub Secrets üzerinden beslenmelidir.
  - Örnek değişkenler: `SIGNING_CERT`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `WINDOWS_SIGNING_PFX`, `WINDOWS_SIGNING_PFX_PASSWORD` vb.
- Scriptler imzalama/notarization adımlarını destekleyecek şekilde şartlara bağlı (conditional) hale getirilebilir.

## 6) İyileştirme Önerileri (Özet)
- **[Mimari uyum]** `jpackage` adımları, proje yapısı ile uyumlu hale getirilmeli veya mevcut script tabanlı dağıtıma geçilmelidir.
- **[Doğru jar ve main sınıf]** `agent-0.0.1-SNAPSHOT.jar` ve `com.company.agent.MainApplication` yerine `alpidiprinteragent-0.0.1-SNAPSHOT-exec.jar` ve `com.alpidiprinteragent.alpidiprinteragent.AlpidiprinteragentApplication`/`service.PlatformServiceWrapper` kullanılmalıdır.
- **[Artefakt standardizasyonu]** `dist/` altındaki çıktılar platforma göre istikrarlı dosya isimleriyle sürümlendirilebilir: `AlpidiPrinterAgent-<os>-<version>.*`.
- **[Test ve kalite]** Ayrı bir CI iş akışı (PR ve push için) sadece `./mvnw -q -B verify` çalıştırıp test ve kalite kapılarını (örn. Sonar) yürütebilir.
- **[Cache optimizasyonu]** `actions/setup-java@v4` ile Maven cache entegre olduğu için ayrı cache adımı kaldırılabilir.

## 7) SSS ve Sorun Giderme
- **[jpackage hataları]** Kaynak klasörler (`installer/linux`, `installer/macos`, `installer/windows`) yoksa komut başarısız olur. Mevcut proje script tabanlı paketlemeye odaklanmıştır.
- **[Launch4j bulunamadı]** Windows runner’da `launch4j` yoksa `.exe` üretimi atlanır. Çözüm: Runner’a `choco install launch4j` adımı eklemek veya sadece JAR/ZIP üretmek.
- **[NSIS yok]** Installer üretimi atlanır. Çözüm: `choco install nsis` adımı eklemek veya installer adımlarını devre dışı bırakmak.
- **[jlink başarısız]** Modüler olmayan projelerde `jlink` kısıtlıdır. Scriptler zaten fallback olarak portable paket üretir.

---
Bu rehber, mevcut iş akışını açıklarken aynı zamanda `alpidiprinteragent` projesinin kendi paketleme altyapısıyla uyumlu CI/CD stratejisini önerir. İhtiyaca göre `Release` iş akışı ve imzalama/notarization adımları eklenerek üretim dağıtım süreci tamamlanabilir.

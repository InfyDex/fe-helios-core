import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Optional override when google-services.json has no Web client (type 3):
// android/local.properties → GOOGLE_SERVER_CLIENT_ID=....apps.googleusercontent.com
val localProperties = Properties()
val localPropsFile = rootProject.file("local.properties")
if (localPropsFile.exists()) {
    localPropsFile.inputStream().use { localProperties.load(it) }
}
val googleServerClientIdFromLocal: String =
    localProperties.getProperty("GOOGLE_SERVER_CLIENT_ID", "").trim()

/** Web OAuth client (Firebase `oauth_client` entry with `client_type` 3). */
fun webOAuthClientIdFromGoogleServicesJson(jsonFile: File): String? {
    if (!jsonFile.exists()) return null
    val text = jsonFile.readText()
    val markers = listOf("\"client_type\": 3", "\"client_type\":3")
    val clientIdPattern =
        Regex(""""client_id"\s*:\s*"(\d+-[A-Za-z0-9_.-]+\.apps\.googleusercontent\.com)"""")
    for (marker in markers) {
        var idx = 0
        while (idx < text.length) {
            val pos = text.indexOf(marker, idx)
            if (pos < 0) break
            val forward = text.substring(pos, (pos + 200).coerceAtMost(text.length))
            clientIdPattern.find(forward)?.groupValues?.get(1)?.let {
                return it
            }
            val backward = text.substring((pos - 200).coerceAtLeast(0), pos)
            clientIdPattern.findAll(backward).lastOrNull()?.groupValues?.get(1)?.let {
                return it
            }
            idx = pos + marker.length
        }
    }
    return null
}

val googleServicesJson = file("${project.projectDir}/google-services.json")
val webClientIdFromJson = webOAuthClientIdFromGoogleServicesJson(googleServicesJson)

// The Google Services Gradle plugin already writes `default_web_client_id` when
// google-services.json includes a Web OAuth client (client_type 3). Do NOT use
// resValue() in that case or mergeDebugResources fails with "Duplicate resources".
val shouldInjectWebClientViaResValue =
    webClientIdFromJson == null && googleServerClientIdFromLocal.isNotEmpty()

if (webClientIdFromJson == null && googleServerClientIdFromLocal.isEmpty()) {
    println(
        "\n" +
            "====================================================================\n" +
            "HELIOS / Google Sign-In (Android): No Web OAuth client ID found.\n" +
            "  - google-services.json has no oauth_client with \"client_type\": 3, AND\n" +
            "  - android/local.properties has no GOOGLE_SERVER_CLIENT_ID=...\n" +
            "Fix: In Google Cloud Console create an OAuth 2.0 *Web application* client\n" +
            "  (same project as Firebase), then EITHER:\n" +
            "  A) Add SHA-1 in Firebase, enable Google Sign-In, re-download JSON until\n" +
            "     oauth_client includes a Web (type 3) entry, OR\n" +
            "  B) Add to android/local.properties:\n" +
            "     GOOGLE_SERVER_CLIENT_ID=<your-web-client-id>.apps.googleusercontent.com\n" +
            "====================================================================\n",
    )
}

android {
    namespace = "com.infydex.helios"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.infydex.helios"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        if (shouldInjectWebClientViaResValue) {
            resValue("string", "default_web_client_id", googleServerClientIdFromLocal)
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

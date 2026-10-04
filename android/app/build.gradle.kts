import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val brandsDirectory = rootProject.projectDir.parentFile.resolve("brands")
val brandBuildConfigs = brandsDirectory.listFiles()
    .orEmpty()
    .filter { it.isDirectory && !it.name.startsWith("_") }
    .sortedBy { it.name }
    .map { brandDirectory ->
        val configFile = brandDirectory.resolve("brand.json")
        if (!configFile.isFile) {
            throw GradleException("Brand '${brandDirectory.name}' is missing ${configFile.path}.")
        }

        val config = try {
            JsonSlurper().parse(configFile) as? Map<*, *>
                ?: throw GradleException("${configFile.path} must contain a JSON object.")
        } catch (error: Exception) {
            throw GradleException("Could not read ${configFile.path}: ${error.message}", error)
        }
        val brandId = config["id"] as? String
            ?: throw GradleException("${configFile.path} must define a string 'id'.")
        val androidConfig = config["android"] as? Map<*, *>
            ?: throw GradleException("${configFile.path} must define an 'android' object.")
        val applicationId = androidConfig["applicationId"] as? String
            ?: throw GradleException("${configFile.path} must define 'android.applicationId'.")
        if (!applicationId.matches(Regex("""^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$"""))) {
            throw GradleException(
                "${configFile.path} has invalid android.applicationId '$applicationId'.",
            )
        }

        if (brandId != brandDirectory.name) {
            throw GradleException(
                "Brand id '$brandId' must match its folder '${brandDirectory.name}'.",
            )
        }
        if (!brandId.matches(Regex("^[a-z][a-z0-9_]*$"))) {
            throw GradleException("Brand id '$brandId' is not a valid flavor name.")
        }

        brandId to applicationId
    }

if (brandBuildConfigs.isEmpty()) {
    throw GradleException("No brand configs found in ${brandsDirectory.path}.")
}

val duplicateApplicationIds = brandBuildConfigs
    .groupBy { it.second }
    .filterValues { it.size > 1 }
    .keys
if (duplicateApplicationIds.isNotEmpty()) {
    throw GradleException(
        "Brand applicationId values must be unique. Duplicates: ${duplicateApplicationIds.joinToString()}",
    )
}

android {
    namespace = "com.example.event_scan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.event_scan"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "brand"
    productFlavors {
        brandBuildConfigs.forEach { (brandId, brandApplicationId) ->
            create(brandId) {
                dimension = "brand"
                applicationId = brandApplicationId
            }
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

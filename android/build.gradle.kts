group = "com.fload.attribution.flutter"
version = "1.0.0"

buildscript {
    val kotlinVersion = "2.4.0"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// The Fload Android SDK is built by JitPack from
// github.com/fload-ai/fload-attribution-android until it is on Maven Central.
// The app resolves it, so the app's projects need JitPack too, limited to that
// one group. (An app whose settings use FAIL_ON_PROJECT_REPOS adds it itself;
// see the README.)
rootProject.allprojects {
    repositories {
        maven("https://jitpack.io") {
            content { includeGroup("com.github.fload-ai") }
        }
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "com.fload.attribution.flutter"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        // The Fload Android SDK needs API 24.
        minSdk = 24
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // The Fload Android SDK, built by JitPack from github.com/fload-ai/fload-attribution-android.
    implementation("com.github.fload-ai:fload-attribution-android:1.0.1")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.0.0")
}

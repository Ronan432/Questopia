import org.jetbrains.compose.desktop.application.dsl.TargetFormat

plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.compose.multiplatform)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.kotlin.serialization)
}

dependencies {
    implementation(compose.desktop.currentOs)
    implementation(compose.material3)
    implementation(compose.materialIconsExtended)
    implementation(compose.components.resources)

    // KMP Core & Serialization
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.ktor.client.core)
    implementation(libs.multiplatform.settings)
    implementation(libs.multiplatform.settings.no.arg)
}

compose.desktop {
    application {
        mainClass = "org.qp.desktop.MainKt"

        nativeDistributions {
            targetFormats(TargetFormat.Dmg, TargetFormat.Msi, TargetFormat.Deb, TargetFormat.Exe)
            packageName = "Questopia"
            packageVersion = "1.0.0"
            description = "Questopia Desktop - Interactive Fiction & Text Quest Player"
            copyright = "© 2026 Questopia Team"
            vendor = "Questopia"

            windows {
                menu = true
                shortcut = true
                dirChooser = true
                perUserInstall = true
            }
        }
    }
}

tasks.withType<JavaExec> {
    val nativeLibDir = rootProject.file("libs/native/windows-x64").absolutePath
    jvmArgs("-Djava.library.path=$nativeLibDir", "-Dskiko.renderApi=VULKAN")
    systemProperty("java.library.path", nativeLibDir)
    systemProperty("skiko.renderApi", "VULKAN")
}

allprojects {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        // Required for background_fetch and other plugins
        maven {
            url = uri("https://developer.huawei.com/repo/")
        }
        maven {
            url = uri("https://www.jitpack.io")
        }
        // Additional repository for background_fetch plugin
        maven {
            url = uri("https://plugins.gradle.org/m2/")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

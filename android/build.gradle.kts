allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val configureAndroid: Project.() -> Unit = {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val setCompileSdk = android.javaClass.methods.firstOrNull { 
                    it.name == "setCompileSdk" && it.parameterTypes.size == 1 && (it.parameterTypes[0] == Int::class.javaPrimitiveType || it.parameterTypes[0] == Integer::class.java) 
                }
                setCompileSdk?.invoke(android, 36)
            } catch (_: Throwable) {}

            try {
                val compileSdkVersion = android.javaClass.methods.firstOrNull { 
                    it.name == "compileSdkVersion" && it.parameterTypes.size == 1 && (it.parameterTypes[0] == Int::class.javaPrimitiveType || it.parameterTypes[0] == Integer::class.java) 
                }
                compileSdkVersion?.invoke(android, 36)
            } catch (_: Throwable) {}

            try {
                val setCompileSdkVersion = android.javaClass.methods.firstOrNull { 
                    it.name == "setCompileSdkVersion" && it.parameterTypes.size == 1 && (it.parameterTypes[0] == Int::class.javaPrimitiveType || it.parameterTypes[0] == Integer::class.java) 
                }
                setCompileSdkVersion?.invoke(android, 36)
            } catch (_: Throwable) {}
        }
    }

    if (state.executed) {
        configureAndroid()
    } else {
        afterEvaluate {
            configureAndroid()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

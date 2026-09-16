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

// 统一所有子项目(含第三方插件)Java 侧的 JVM target 到 17。
//
// 为什么需要:部分插件(tflite_flutter 等)自己的 Java 侧仍写死 1.8,而 Kotlin 侧
// 跟随工具链是 17。新版 Gradle/AGP 会因同一模块内两者不一致直接失败
// (Inconsistent JVM-target compatibility)。
//
// 用 configureEach 而不是 afterEvaluate:下面的 evaluationDependsOn(":app") 会提前
// 触发求值,那时再注册 afterEvaluate 会抛 "project is already evaluated"。
// configureEach 是惰性的,任务真正实现时才应用,没有这个时序问题。
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

# TensorFlow Lite:反射调用的 GPU delegate / native 入口,别被裁掉
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Flutter 与插件常见反射入口
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

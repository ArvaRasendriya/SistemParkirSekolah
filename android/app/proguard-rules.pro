# Keep OkHttp and Okio (used by UCrop and other network libraries)
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-dontwarn okio.**

# Keep UCrop library classes
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

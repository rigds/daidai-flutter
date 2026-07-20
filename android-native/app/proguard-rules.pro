-keepattributes Signature
-keepattributes *Annotation*

-keep class com.daidai.panel.data.model.** { *; }
-keep class com.daidai.panel.core.network.ApiService { *; }

-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

-keep class retrofit2.** { *; }
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}

-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
-dontwarn org.conscrypt.**

-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }

-keep class androidx.security.crypto.** { *; }

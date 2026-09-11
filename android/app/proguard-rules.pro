# ZEGOCLOUD ZPNs - keep all classes to prevent R8 from stripping
# generic type signatures used by ZPNsConverter (Gson TypeToken)
-keep class im.zego.** { *; }
-dontwarn im.zego.**

# Gson TypeToken generic signature preservation (required by ZPNsConverter)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }

# Flutter ZPNs FCM Receiver
-keep class im.zego.zpns_flutter.** { *; }
-keep class im.zego.zpns_android_plugin_fcm.** { *; }

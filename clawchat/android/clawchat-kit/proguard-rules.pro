# kotlinx.serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# ClawChat protocol models
-keep,includedescriptorclasses class com.clawchat.kit.protocol.**$$serializer { *; }
-keepclassmembers class com.clawchat.kit.protocol.** {
    *** Companion;
}
-keepclasseswithmembers class com.clawchat.kit.protocol.** {
    kotlinx.serialization.KSerializer serializer(...);
}

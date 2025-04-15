-injars       checkstyle/target/checkstyle-10.21.3-SNAPSHOT-all.jar
-outjars      artifact_proguard.jar
# Identified with jdeps
-libraryjars  <java.home>/jmods/java.base.jmod
-libraryjars  <java.home>/jmods/java.logging.jmod
-libraryjars  <java.home>/jmods/java.desktop.jmod
-libraryjars  <java.home>/jmods/java.xml.jmod

-dontobfuscate # Might break stuff, especially enums
#-printmapping artifacts/mapping.txt

# Keep main class
-keep class com.puppycrawl.tools.checkstyle.** {
    *;
}

# Keep classes after run-time errors
-keep class org.apache.commons.logging.**{*;}
-keep class sy.apache.commons.logging.**{*;}
-keep class picocli.** { *; }
-keepclassmembers class picocli.** { *; }

-dontwarn # There are a lot of warnings from proguard, but they're not necessarily critical if the program runs fine.
-dontnote

# ProGuard optimization options
-verbose
-mergeinterfacesaggressively  # Aggressively merges interfaces (use with caution)
-optimizeaggressively  # Optimizes aggressively (might break things)
-optimizationpasses 50  # Number of optimization passes


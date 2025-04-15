-injars       target/artifact.jar
-outjars      artifacts/artifact_proguard.jar
# Identified with jdeps
-libraryjars  <java.home>/jmods/java.base.jmod
-libraryjars  <java.home>/jmods/java.desktop.jmod
-libraryjars  <java.home>/jmods/java.logging.jmod
-libraryjars  <java.home>/jmods/java.xml.jmod
-libraryjars  <java.home>/jmods/jdk.xml.dom.jmod

-dontobfuscate # Might break stuff, especially enums
#-printmapping artifacts/mapping.txt

# Keep our program
-keep class org.example.BenchmarkRunner {
    *;
}

# Ignore unuseful warnings
-dontwarn com.google.errorprone.**
-dontwarn org.jspecify.annotations.**
-dontnote

# Added rules after classes were found to be missing at run time
-keep class org.xhtmlrenderer.render.**{*;}
-keep class org.slf4j.**{*;}

# ProGuard optimization options
-verbose
-mergeinterfacesaggressively  # Aggressively merges interfaces (use with caution)
-optimizeaggressively  # Optimizes aggressively (might break things)


-optimizationpasses 50  # Number of optimization passes
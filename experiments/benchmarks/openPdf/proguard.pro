-injars       target/artifact.jar
-outjars      artifacts/artifact_proguard.jar
# Identified with jdeps
-libraryjars  <java.home>/jmods/java.base.jmod
-libraryjars  <java.home>/jmods/java.desktop.jmod
-libraryjars  <java.home>/jmods/java.xml.jmod

-dontobfuscate # Might break stuff, especially enums
-printmapping artifacts/mapping.txt

# Keep our program
-keep class org.example.BenchmarkRunner {
    *;
}

# Keep classes after runtime errors
-keep class com.lowagie.bouncycastle.BouncyCastleHelper {*;}
# Added rules to not produce warnings for libraries we do not use
-dontwarn org.bouncycastle.**
-dontwarn org.apache.fop.**
-dontwarn com.ibm.icu.**
-dontwarn java.lang.invoke.MethodHandle

# ProGuard optimization options
-verbose
-mergeinterfacesaggressively  # Aggressively merges interfaces (use with caution)
# Aggressive optimization ruined the program so we can't use this feature
-optimizeaggressively  # Optimizes aggressively (might break things)

-optimizationpasses 50  # Number of optimization passes
-injars       target/artifact.jar
-outjars      artifacts/artifact_proguard.jar
# Identified with jdeps
-libraryjars  <java.home>/jmods/java.base.jmod
-libraryjars  <java.home>/jmods/java.desktop.jmod
-libraryjars  <java.home>/jmods/java.xml.jmod

-dontobfuscate # Obfuscation enabled
#-printmapping artifacts/mapping.txt

# Preserve critical classes and members
-keep class org.example.BenchmarkRunner {*;}

# Preserve classes after runtime errors
-keep enum org.locationtech.jts.io.** {*;}
# Ignore notes
-dontnote **
#-dontwarn ** 

# ProGuard optimization options
-verbose
-mergeinterfacesaggressively  # Aggressively merges interfaces (use with caution)
-optimizeaggressively  # Optimizes aggressively (use with caution)
-optimizationpasses 50  # Number of optimization passes
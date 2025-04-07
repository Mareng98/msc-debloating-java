-injars       target/artifact.jar
-outjars      artifacts/artifact_proguard.jar
# Identified with jdeps
-libraryjars  <java.home>/jmods/java.base.jmod
-libraryjars  <java.home>/jmods/java.desktop.jmod
-libraryjars  <java.home>/jmods/java.compiler.jmod
-libraryjars  <java.home>/jmods/java.instrument.jmod
-libraryjars  <java.home>/jmods/java.logging.jmod
-libraryjars  <java.home>/jmods/java.management.jmod
-libraryjars  <java.home>/jmods/java.xml.jmod
-libraryjars  <java.home>/jmods/jdk.attach.jmod
-libraryjars  <java.home>/jmods/jdk.jdi.jmod
-libraryjars  <java.home>/jmods/jdk.unsupported.jmod

-dontobfuscate # Obfuscation enabled
#-printmapping artifacts/mapping.txt

# Preserve critical classes and members
-keep class org.example.BenchmarkRunner {*;}

# Preserve classes after runtime errors
-keep class com.github.javaparser.ast.validator.** { *; }



# Ignore notes
-dontnote **
-dontwarn ** # There was one warning concerning java.nio but it could be ignored

# ProGuard optimization options
-verbose
-mergeinterfacesaggressively  # Aggressively merges interfaces (use with caution)
-optimizeaggressively  # Optimizes aggressively (use with caution)
-optimizationpasses 40  # Number of optimization passes
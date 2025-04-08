-injars       target/artifact.jar
-outjars      artifacts/artifact_proguard.jar
# Identified with jdeps
-libraryjars  <java.home>/jmods/java.base.jmod
-libraryjars  <java.home>/jmods/java.desktop.jmod
-libraryjars  <java.home>/jmods/java.compiler.jmod
-libraryjars  <java.home>/jmods/java.logging.jmod
-libraryjars  <java.home>/jmods/java.xml.jmod
-libraryjars  <java.home>/jmods/java.sql.jmod
-libraryjars  <java.home>/jmods/jdk.unsupported.jmod

-dontobfuscate # Obfuscation enabled
#-printmapping artifacts/mapping.txt

# Preserve critical classes and members
-keep class org.example.BenchmarkRunner {*;}

# Preserve classes after runtime errors
-keep class com.google.template.soy.basicfunctions.** {*;}
-keep class com.google.template.soy.shared.internal.** {*;}
-keep class com.google.template.soy.bidifunctions.** {*;}
-keep class com.google.template.soy.i18ndirectives.** {*;}
-keep class com.google.template.soy.passes.** {*;}
-keep enum com.google.template.soy.** {*;}
# Ignore notes
-dontnote **
-dontwarn ** 

# ProGuard optimization options
-verbose
-mergeinterfacesaggressively  # Aggressively merges interfaces (use with caution)
-optimizeaggressively  # Optimizes aggressively (use with caution)
-optimizationpasses 1  # Number of optimization passes - 1 was the highest we could go or things started breaking.
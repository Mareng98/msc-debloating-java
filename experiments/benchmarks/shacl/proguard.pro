-injars       target/artifact.jar
-outjars      artifacts/artifact_proguard.jar
# Identified with jdeps
-libraryjars  <java.home>/jmods/java.base.jmod
-libraryjars  <java.home>/jmods/java.desktop.jmod
-libraryjars  <java.home>/jmods/java.compiler.jmod
-libraryjars  <java.home>/jmods/java.logging.jmod
-libraryjars  <java.home>/jmods/java.net.http.jmod
-libraryjars  <java.home>/jmods/java.scripting.jmod
-libraryjars  <java.home>/jmods/java.security.sasl.jmod
-libraryjars  <java.home>/jmods/java.sql.jmod
-libraryjars  <java.home>/jmods/java.xml.jmod
-libraryjars  <java.home>/jmods/java.xml.crypto.jmod

-dontobfuscate # Obfuscation enabled
#-printmapping artifacts/mapping.txt

# Preserve critical classes and members
-keep class org.example.BenchmarkRunner {*;}

# Preserve classes after runtime errors
-keep class org.apache.jena.riot.system.** {*;}
-keep class org.apache.jena.sparql.system.** {*;}
-keep class org.apache.jena.rdfs.sys.** {*;}
-keep class com.github.benmanes.caffeine.cache.** {*;}
-keep class org.topbraid.shacl.model.impl.** {*;}

# There are a ton of warnings from proguard, but they're not necessarily critical if the program runs fine.
-dontwarn **.**
-dontnote **

-keep class * implements org.apache.jena.riot.system.ReaderRIOTFactory { *; }

# Preserve method names used by lambdas (common in Jena's internal factories)
-keepclassmembers class * {
    *** lambda$*(...);
}

# ProGuard optimization options
-verbose
-mergeinterfacesaggressively  # Aggressively merges interfaces (use with caution)
-optimizeaggressively  # Optimizes aggressively (use with caution)
-optimizationpasses 15  # Number of optimization passes - For shacl it repeatedly tries to remove the same 3 write-only fields ad infinitum it seems, so we shorten it to 15 to save time.
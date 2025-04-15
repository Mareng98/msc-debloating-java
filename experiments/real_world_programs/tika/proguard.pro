-injars       tika/tika-app/target/tika-app-3.1.0.jar
-outjars      artifact_proguard.jar
# Identified with jdeps
-libraryjars  <java.home>/jmods/java.base.jmod
-libraryjars  <java.home>/jmods/java.compiler.jmod
-libraryjars  <java.home>/jmods/java.datatransfer.jmod
-libraryjars  <java.home>/jmods/java.desktop.jmod
-libraryjars  <java.home>/jmods/java.logging.jmod
-libraryjars  <java.home>/jmods/java.management.jmod
-libraryjars  <java.home>/jmods/java.naming.jmod
-libraryjars  <java.home>/jmods/java.rmi.jmod
-libraryjars  <java.home>/jmods/java.scripting.jmod
-libraryjars  <java.home>/jmods/java.security.jgss.jmod
-libraryjars  <java.home>/jmods/java.sql.jmod
-libraryjars  <java.home>/jmods/java.xml.jmod
-libraryjars  <java.home>/jmods/java.xml.crypto.jmod
-libraryjars D:/MasterThesis/successfulRealWorldPrograms/apache-tika/javax.servlet-api-4.0.1.jar

-dontobfuscate # Might break stuff, especially enums
#-printmapping artifacts/mapping.txt

# Added when using proguard
-keep class org.apache.tika.** { *; }
-keep class org.apache.commons.logging.** {*;}
-keep class org.apache.logging.** { *; }
-keep class org.apache.pdfbox.** { *; }
-keep enum org.apache.tika.** { *; } # Keep all enums
# Added at runtime due to errors
-keep public class com.github.jaiimageio.** {*;}
-keep class org.apache.fontbox.** { *; }

# There are a ton of warnings from proguard, but they're not necessarily critical if the program runs fine.
-dontwarn **.**
-dontnote **

# ProGuard optimization options
-verbose
-mergeinterfacesaggressively  # Aggressively merges interfaces (use with caution)
-optimizeaggressively  # Optimizes aggressively (might break things)

-optimizationpasses 50  # Number of optimization passes
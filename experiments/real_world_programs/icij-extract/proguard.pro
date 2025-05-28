-injars       extract/extract-cli/target/extract-cli-7.4.0.jar
-outjars      artifact_proguard.jar
# Identified with jdeps
-libraryjars  <java.home>/jmods/java.base.jmod
-libraryjars  <java.home>/jmods/java.desktop.jmod
-libraryjars  <java.home>/jmods/java.logging.jmod
-libraryjars  <java.home>/jmods/java.sql.jmod
-libraryjars  <java.home>/jmods/java.xml.jmod

-dontobfuscate # Might break stuff, especially enums
#-printmapping artifacts/mapping.txt

# Added when using proguard
-keep class org.icij.** {*;}

# Added at runtime due to errors
-keep class org.apache.xerces.** {*;}


# Everything here was imported from TIKA --->
-keep class org.apache.tika.** { *; }
-keep class org.apache.commons.logging.** {*;}
-keep class org.apache.logging.** { *; }
-keep class org.apache.pdfbox.** { *; }
-keep enum org.apache.tika.** { *; } # Keep all enums
#-keep public class com.github.jaiimageio.** {*;} # This one wasn't necessary for extract 
-keep class org.apache.fontbox.** { *; }
# <---

# There are a ton of warnings from proguard, but they're not necessarily critical if the program runs fine.
-dontwarn **.**
-dontnote **

# This optimization caused an illegal access error, so we disable it
-optimizations !field/generalization/class
# After increasing optimization passes from 1 to 5 we got:
#Error: Unable to initialize main class org.icij.extract.cli.Main
#Caused by: java.lang.ClassFormatError: Duplicate method name "getInputStream$4ad57608" with signature "()Ljava.io.ByteArrayInputStream;" in class file org/bouncycastle/cms/PasswordRecipient
-keep class org.bouncycastle.cms.PasswordRecipient {*;}

# ProGuard optimization options
-verbose
-mergeinterfacesaggressively  # Aggressively merges interfaces (use with caution)
-optimizeaggressively  # Optimizes aggressively (might break things)

-optimizationpasses 15  # Number of optimization passes
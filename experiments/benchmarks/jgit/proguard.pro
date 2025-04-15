-injars       target/artifact.jar
-outjars      artifacts/artifact_proguard.jar
# Identified with jdeps
-libraryjars  <java.home>/jmods/java.base.jmod
-libraryjars  <java.home>/jmods/java.management.jmod
-libraryjars  <java.home>/jmods/java.xml.jmod
-libraryjars  <java.home>/jmods/java.sql.jmod
-libraryjars  <java.home>/jmods/java.security.jgss.jmod

-dontobfuscate # Might break stuff, especially enums
#-printmapping artifacts/mapping.txt

# Keep our program
-keep class org.example.BenchmarkRunner {
    *;
}

# Keep necessary enums
-keep public enum org.eclipse.jgit.lib.**{*;}
-keep public enum org.eclipse.jgit.util.**{*;}
-keep public enum org.eclipse.jgit.revwalk.**{*;}

# Added rules after classes were found to be missing at run time
-keep class org.slf4j.simple.SimpleServiceProvider{*;}

# Added rules after proguard obfuscation didn't work
#-keep public class org.eclipse.jgit.internal.JGitText {*;}
#-keep public class org.eclipse.jgit.api.MergeCommand$FastForwardMode$Merge {*;}

# ProGuard optimization options
-verbose
-mergeinterfacesaggressively  # Aggressively merges interfaces (use with caution)
-optimizeaggressively  # Optimizes aggressively (might break things)
-optimizationpasses 50  # Number of optimization passes
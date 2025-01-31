-injars       target/jgit_stresstest-SNAPSHOT.jar
-outjars      stresstest_out.jar
-libraryjars  <java.home>/jmods/java.base.jmod
-libraryjars  <java.home>/jmods/java.management.jmod
-libraryjars  <java.home>/jmods/java.xml.jmod
-libraryjars  <java.home>/jmods/java.sql.jmod
-libraryjars  <java.home>/jmods/java.security.jgss.jmod
-dontobfuscate

-keep class org.example.LocalGitCommitStressTest {
    *;
}

# Keep required classes for jgit (Git processing)
-keep public class org.eclipse.jgit.api.Git { *; }
-keep public class org.eclipse.jgit.api.errors.GitAPIExceptionn { *; }
-keep public class org.eclipse.jgit.lib.** { *; } # Broadened at run time
-keep public class org.eclipse.jgit.storage.file.FileRepositoryBuilder { *; } 

# Added rules after hidden classes were found to be missing at run time
-keep public class org.eclipse.jgit.util.sha1.** {*;} # org.eclipse.jgit.util.sha1.SHA1$Sha1Implementation not available
-keep public class org.eclipse.jgit.util.io.** {*;} #  org.eclipse.jgit.util.io.AutoLFInputStream$StreamFlag not an enum
-keep public class org.eclipse.jgit.revwalk.RevSort {*;} # org.eclipse.jgit.revwalk.RevSort not an enum
# Keep java io
-keep public class java.io.File { *; }
-keep public class java.io.IOException { *; }

# Keep java nio
-keep public class java.nio.file.Files { *; }
-keep public class java.nio.file.Paths { *; }

-keep class org.slf4j.** { *; }

# ProGuard optimization options
-verbose
#-mergeinterfacesaggressively  # Aggressively merges interfaces (use with caution)
#-optimizeaggressively  # Optimizes aggressively (might break things)
-optimizationpasses 1  # Number of optimization passes
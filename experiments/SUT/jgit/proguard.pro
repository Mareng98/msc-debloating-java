-injars       target/jgit_stresstest-SNAPSHOT.jar
-outjars      proguard_out.jar
# Identified with jdeps
-libraryjars  <java.home>/jmods/java.base.jmod
-libraryjars  <java.home>/jmods/java.management.jmod
-libraryjars  <java.home>/jmods/java.xml.jmod
-libraryjars  <java.home>/jmods/java.sql.jmod
-libraryjars  <java.home>/jmods/java.security.jgss.jmod

#-dontobfuscate # Might break stuff, especially enums
-printmapping mapping.txt

# Keep our program
-keep class org.example.LocalGitCommitStressTest {
    *;
}

# Keep required classes for jgit (Git processing)
-keep public class org.eclipse.jgit.api.Git { # Save all commands we use in Git
    public <init>(...);
    public static org.eclipse.jgit.api.InitCommand init();
    public org.eclipse.jgit.api.AddCommand add();
    public org.eclipse.jgit.api.CommitCommand commit();
    public org.eclipse.jgit.api.RenameBranchCommand branchRename();
    public org.eclipse.jgit.api.CheckoutCommand checkout();
    public org.eclipse.jgit.api.RmCommand rm();
    public org.eclipse.jgit.api.MergeCommand merge();
    public org.eclipse.jgit.api.DeleteBranchCommand branchDelete();
}
-keep public class org.eclipse.jgit.api.errors.GitAPIExceptionn { *; }
-keep public class org.eclipse.jgit.lib.Repository { *; }
-keep public class org.eclipse.jgit.lib.ObjectChecker$ErrorType { *; } # Save specific enum
-keep public class org.eclipse.jgit.lib.CoreConfig$* { *; } # Save all enums
-keep public class org.eclipse.jgit.storage.file.FileRepositoryBuilder { *; } 

# Keep java io
-keep public class java.io.File { *; }
-keep public class java.io.IOException { *; }

# Keep java nio
-keep public class java.nio.file.Files { *; }
-keep public class java.nio.file.Paths { *; }

# Added rules after classes were found to be missing at run time
-keep public class org.eclipse.jgit.util.sha1.** {*;} # org.eclipse.jgit.util.sha1.SHA1$Sha1Implementation not available
-keep public class org.eclipse.jgit.util.io.** {*;} #  org.eclipse.jgit.util.io.AutoLFInputStream$StreamFlag not an enum
-keep public class org.eclipse.jgit.revwalk.RevSort {*;} # org.eclipse.jgit.revwalk.RevSort not an enum
-keep class org.slf4j.** { *; }

# Added rules after proguard obfuscation didn't work
-keep public class org.eclipse.jgit.internal.JGitText {*;}
-keep public class org.eclipse.jgit.api.MergeCommand$FastForwardMode$Merge {*;}

# ProGuard optimization options
-verbose
-mergeinterfacesaggressively  # Aggressively merges interfaces (use with caution)
-optimizeaggressively  # Optimizes aggressively (might break things)


-optimizationpasses 5  # Number of optimization passes
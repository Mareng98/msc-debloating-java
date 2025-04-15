-injars       error-prone-master/core/target/error_prone_core-2.36.0-with-dependencies.jar
-outjars      artifact_proguard.jar
# Identified with jdeps
-libraryjars  <java.home>/jmods/java.base.jmod

-dontobfuscate # Might break stuff, especially enums, doesn't work for this
#-printmapping artifacts/mapping.txt



# There are a ton of warnings from proguard, but they're not necessarily critical if the program runs fine.
-dontwarn **.**
-dontnote **

# ProGuard optimization options
-verbose


# Proguard didn't work with any of the optimization steps, so we'll just have to disable them all
-dontoptimize
-dontshrink
-dontpreverify
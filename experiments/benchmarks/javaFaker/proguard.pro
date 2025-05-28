-injars       target/artifact.jar
-outjars      artifacts/artifact_proguard.jar
# Identified with jdeps
-libraryjars  <java.home>/jmods/java.base.jmod
-libraryjars  <java.home>/jmods/java.desktop.jmod
-libraryjars  <java.home>/jmods/java.logging.jmod
-libraryjars  <java.home>/jmods/java.sql.jmod

-dontobfuscate # Obfuscation enabled
#-printmapping artifacts/mapping.txt

# Preserve critical classes and members
-keep class org.example.BenchmarkRunner {*;}

# Preserve classes after runtime errors
-keepclassmembers class com.github.javafaker.service.FakeValuesService {
    public * resolveExpression(*);
}

# Keep the Address and Name classes
-keep class com.github.javafaker.Address { *; }
-keep class com.github.javafaker.Name { *; }
-keep class com.github.javafaker.PhoneNumber { *; }
-keep class com.github.javafaker.Company { *; }
-keep class com.github.javafaker.Lorem { *; }
-keep class com.github.javafaker.Finance { *; }
-keep class com.github.javafaker.Avatar { *; }
-keep class com.github.javafaker.Shakespeare { *; }

# Ignore notes
-dontnote **

# ProGuard optimization options
-verbose
-mergeinterfacesaggressively  # Aggressively merges interfaces (use with caution)
-optimizeaggressively  # Optimizes aggressively (use with caution)
-optimizationpasses 50  # Number of optimization passes
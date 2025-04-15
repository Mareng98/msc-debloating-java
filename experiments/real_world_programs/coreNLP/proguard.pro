-injars       CoreNLP/target/stanford-corenlp-4.5.8.jar
-outjars      artifact_proguard.jar
# Identified with jdeps
-libraryjars  <java.home>/jmods/java.base.jmod
-libraryjars  <java.home>/jmods/java.logging.jmod
-libraryjars  <java.home>/jmods/java.desktop.jmod
-libraryjars  <java.home>/jmods/java.xml.jmod
-libraryjars  <java.home>/jmods/java.datatransfer.jmod
-libraryjars  <java.home>/jmods/java.management.jmod
-libraryjars  <java.home>/jmods/java.prefs.jmod
-libraryjars  <java.home>/jmods/java.sql.jmod
-libraryjars  D:\MasterThesis\successfulRealWorldPrograms\standfordNLP\protobuf-java-3.25.5.jar # Necessary external dependency, not sure why only this one

-dontobfuscate # Might break stuff, especially enums
#-printmapping artifacts/mapping.txt

# Added when using proguard
-keep class edu.stanford.nlp.pipeline.StanfordCoreNLP{*;}
-keep class edu.stanford.nlp.tagger.maxent.*{*;}

# Added at runtime due to errors
-keep class edu.stanford.nlp.trees.GrammaticalStructure$Extras{*;}
-keep class edu.stanford.nlp.process.AmericanizeFunction{*;}
-keep class edu.stanford.nlp.process.TransformXML$SAXInterface { *; }
-keep interface org.xml.sax.ContentHandler



# There are a ton of warnings from proguard, but they're not necessarily critical if the program runs fine.
-dontwarn **.**
-dontnote **

# ProGuard optimization options
-verbose
-mergeinterfacesaggressively  # Aggressively merges interfaces (use with caution)
-optimizeaggressively  # Optimizes aggressively (might break things)

# Rule that was added when optimization passes were increased from 1 and things started breaking
# Preserve local variable type information to avoid LVTT errors
# This disables "Number of optimized local variable frames:" optimization
-optimizations !code/allocation/variable 

-optimizationpasses 12  # Number of optimization passes
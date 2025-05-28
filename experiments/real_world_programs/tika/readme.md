version: Apache Tika 3.1.0
Steps to replicate:
1. clone project.
2. Checkout tag 3.1.0
3. go into tika-app (This is the module that is used to build the program for all artifacts)
4. build with mvn clean install
5. run:
java -jar target/tika-app-3.1.0.jar --text-all text/*
to process all compatible files in the folder "text".

Verify output correctness: compare output of
java -jar artifacts/artifact_vanilla.jar --text-all text/energyMeasurement.pdf > output.txt
with the output of all other artifacts.

ProGuard:
for some reason we have to include javax.servlet-api as libraryjar for proguard
https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/4.0.1/ > javax.servlet-api-4.0.1.jar

DepClean:
We have to change all "${project.groupId}" into "org.apache.tika" in pom.xml, since depclean can't resolve it for some reason.
Run 'mvn -f pom.xml se.kth.castor:depclean-maven-plugin:2.0.6:depclean -DcreatePomDebloated=true' in the tika-app directory to run depclean.
then build the debloated artifact with: 'mvn -f pom-depclean-debloated.xml clean install -DskipTests' (after renaming debloated file)

DepTrim:
Ensure you use v0.1.2 of deptrim or it won't work.
Run in tika-app:
mvn se.kth.castor:deptrim-maven-plugin:0.1.2:deptrim -DcreateSinglePomSpecialized=true
then run: 
mvn -f pom-deptrim-specialized.xml clean install -DskipTests (after renaming specialized file)

JLink:
run:
jlink --compress=2 --strip-debug --no-header-files --no-man-pages --add-modules java.base,java.desktop,java.xml,java.compiler,java.datatransfer,java.logging,java.management,java.naming,java.rmi,java.scripting,java.security.jgss,java.sql,java.xml.crypto --output artifacts/jlink-runtime
and then run the program with:
artifacts/jlink-runtime/bin/java --add-opens=java.base/java.nio=ALL-UNNAMED --add-exports=java.base/jdk.internal.ref=ALL-UNNAMED -jar artifact_vanilla.jar --text-all text/*
The UNNAMED parameters are necessary to stop an exception from happening, im not sure why.
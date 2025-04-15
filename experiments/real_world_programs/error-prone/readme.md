git tag -l
git checkout v2.36.0
Go to pom in root and remove jdk <version>24< ..., it can be built with java 17.
NOTE: We added maven-shade so that it will be easier to carry out our experiment.

We use the javac command to run error-prone because it's a compile-time plugin. Our command only runs the core of the plugin, making it elligble for a real-world program.

ENSURE THAT THE PATH TO THE JAR FILE IS CORRECT!
#PATH FOR ARTIFACT VANILLA BELOW
javac -J"--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED" -J"--add-opens=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED" -J"--add-opens=jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED" -XDcompilePolicy=simple -processorpath "D:\MasterThesis\successfulRealWorldPrograms\error-prone\error-prone-master\core\artifacts\artifact_vanilla.jar" -Xplugin:ErrorProne --should-stop=ifError=FLOW ShortSet.java
#PATH FOR TARGET BELOW
javac -J"--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED" -J"--add-opens=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED" -J"--add-opens=jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED" -XDcompilePolicy=simple -processorpath "D:\MasterThesis\successfulRealWorldPrograms\error-prone\error-prone-master\core\target\error_prone_core-2.36.0-with-dependencies.jar" -Xplugin:ErrorProne --should-stop=ifError=FLOW ShortSet.java

JLINK:
Sadly because it's the javac command being used, JLink won't work with this program by running java.
Therefore, we compile with only the javac command in mind!
jlink --add-modules jdk.javadoc,jdk.zipfs,java.logging,java.net.http --output jlink-runtime
and run:
D:\MasterThesis\successfulRealWorldPrograms\error-prone\error-prone-master\core\artifacts\jlink-runtime\bin\javac -J"--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED" -J"--add-opens=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED" -J"--add-opens=jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED" -XDcompilePolicy=simple -processorpath "D:\MasterThesis\successfulRealWorldPrograms\error-prone\error-prone-master\core\target\error_prone_core-2.36.0-with-dependencies.jar" -Xplugin:ErrorProne --should-stop=ifError=FLOW ShortSet.java

I Had to find the modules manually, jdeps was not used here.
While javac is different from the java command, it still is responsible for running the code in the plugin/program 
and might have efficiency gain due to the debloating.


DEPCLEAN:
Go to the "core" module
Run 'mvn -f pom.xml se.kth.castor:depclean-maven-plugin:2.0.6:depclean -DcreatePomDebloated=true' in core
then build with 'mvn -f pom-debloated.xml clean package -D"maven.test.skip"=true'
and run with the above javac command (not with jlink artifact)

DEPTRIM:
Go to the "core" module
Generate deptrim specialized:
mvn se.kth.castor:deptrim-maven-plugin:0.1.2:deptrim -DcreateSinglePomSpecialized=true
Run it:
mvn -f pom-deptrim-specialized.xml clean package -D"maven.test.skip"=true
Some errors were generated when building, so:
#Revert back to unspecialized icu4j
        <dependency>
      <!-- ICU License -->
      <groupId>com.ibm.icu</groupId>
      <artifactId>icu4j</artifactId>
      <version>74.2</version>
      <scope>test</scope>
    </dependency>
#Revert back to unspecialized guava
    <dependency>
      <!-- Apache 2.0 -->
      <groupId>com.google.guava</groupId>
      <artifactId>guava</artifactId>
      <version>${guava.version}</version>
    </dependency>
Runtime errors:
#Revert back to unspecialized check_api
    <dependency>
      <!-- Apache 2.0 -->
      <groupId>com.google.errorprone</groupId>
      <artifactId>error_prone_check_api</artifactId>
      <version>${project.version}</version>
    </dependency>
#Revert back
    <dependency>
      <!-- Apache 2.0 -->
      <groupId>com.google.googlejavaformat</groupId>
      <artifactId>google-java-format</artifactId>
      <version>1.19.1</version>
    </dependency>

PROGUARD:
Proguard had a bug where it changed an unrecognized variable or something similar in the bytecode of error-prone suppliers.
This caused us to not be able to do any of the optimization steps, as there is no way to tell proguard to not alter a file.
It still somehow reduced the size slightly of the artifact.

javac -J"--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED" -J"--add-opens=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED" -J"--add-opens=jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED" -XDcompilePolicy=simple -processorpath "D:\MasterThesis\successfulRealWorldPrograms\error-prone\\error-prone-master\core\artifacts\artifact_proguard.jar" -Xplugin:ErrorProne --should-stop=ifError=FLOW examples/ShortSet.java

It can also be run with this command to process all java files in a folder and output the results:
javac -J"--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED" -J"--add-exports=jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMEDutil=ALL-UNNAMED" -J"--add-opens=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED" -J"--add-opens=jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED" -XDcompilePolicy=simple -processorpath "D:\MasterThesis\successfulRealWorldPrograms\error-prone\error-prone-master\core\artifacts\artifact_proguard.jar" -Xplugin:ErrorProne --should-stop=ifError=FLOW examples/* *> vanilla_output.txt
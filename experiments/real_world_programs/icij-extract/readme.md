version = v2.0.0
install with:
mvn clean install -DskipTests -D"gpg.skip"=true
Here we're skipping gpg signing, which doesn't change the execution of the jar.
java -jar target/extract-cli-7.4.0.jar spew -o stdout --outputFormat text --outputMetadata no --ocr no text/*

You can also run the artifacts and put all of the output in a text file:
java -jar artifact_proguard.jar spew -o stdout --outputFormat text --outputMetadata no --ocr no text/* *> debloating_output.txt

DEPCLEAN
mvn -f pom.xml se.kth.castor:depclean-maven-plugin:2.0.6:depclean -DcreatePomDebloated=true
then:
mvn -f pom-debloated.xml clean install -DskipTests -D"gpg.skip"=true
Depclean wrongly includes some libraries, but one that stops the execution is the following library that we have to remove:
    <dependency>
      <groupId>org.apache.tika</groupId>
      <artifactId>tika-parser-html-module</artifactId>
      <version>2.4.1</version>
      <scope>compile</scope>
      <exclusions>
        <exclusion>
          <groupId>org.apache.tika</groupId>
          <artifactId>tika-parser-html-commons</artifactId>
        </exclusion>
      </exclusions>
      <optional>false</optional>
    </dependency>

and

    <dependency>
      <groupId>org.apache.zookeeper</groupId>
      <artifactId>zookeeper</artifactId>
      <version>3.6.2</version>
      <scope>compile</scope>
      <optional>false</optional>
    </dependency>

DEPTRIM
run mvn -f pom.xml se.kth.castor:deptrim-maven-plugin:0.1.2:deptrim -DcreateSinglePomSpecialized=true -DskipTests -D"gpg.skip"=true
mvn -f pom-deptrim-specialized.xml clean install -DskipTests -D"gpg.skip"=true
The same dependency as in depclean is creating issues, you have to delete that one from the specialized pom too.

JLINK:
jlink --compress=2 --strip-debug --no-header-files --no-man-pages --add-modules java.base,java.desktop,java.xml,java.logging,java.sql,jdk.management,java.naming --output jlink-runtime



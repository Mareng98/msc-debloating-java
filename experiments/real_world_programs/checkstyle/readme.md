built with maven 3.9.9 and java 17.0.9
clone the project or 2 tests will fail since it relies on github to check some things.
https://checkstyle.sourceforge.io/cmdline.html

build the checkstyle-10.21.3-SNAPSHOT-all.jar artifact: 'mvn clean package "-Passembly,no-validations"'

run it: java -jar target/checkstyle-10.21.3-SNAPSHOT-all.jar -c /sun_checks.xml Example.java
where Example.java is just some java class.
You can also run it on all files in a folder: java -jar target/checkstyle-10.21.3-SNAPSHOT-all.jar -c /sun_checks.xml examples/*

DepClean:
run: mvn se.kth.castor:depclean-maven-plugin:2.0.6:depclean -DcreatePomDebloated=true
We have to skip maven-enforcer-plugin since depclean changes the pom file structure.
run: mvn -f pom-depclean-debloated.xml -D"enforcer.skip"=true clean package "-Passembly,no-validations"
I noticed that depclean adds some unnecessary dependencies, for example it adds org.slf4j, which was not imported in the original pom file, but was set as an "exclusion" from the net.sf.saxon dependency.

DepTrim:
run deptrim: Include the deptrim plugin with specialize option in build around line 2300.
run it with the -f command.
In pom-deptrim-specialized.xml (after renaming):
swap back nl.jqno.equalsverifier and commons-beanutils to the original dependencies. Ensure that you remove commons-logging plugin as well, since it's connected to this missidentification.
Then run: mvn -f pom-deptrim-specialized.xml -D"enforcer.skip"=true clean package "-Passembly,no-validations"

JLink:
Run: jdeps --ignore-missing-deps --list-deps artifacts/artifact_vanilla.jar
Copy the list of modules and create the runtime:
jlink --compress=2 --strip-debug --no-header-files --no-man-pages --add-modules java.base,java.compiler,java.desktop,java.instrument,java.logging,java.management,java.naming,java.security.jgss,java.sql,java.xml,jdk.attach,jdk.jdi,jdk.unsupported --output artifacts/jlink-runtime
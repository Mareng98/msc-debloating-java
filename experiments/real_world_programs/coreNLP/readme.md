1. git tag -l -> git checkout v4.5.8 -> run <mvn clean package -D"maven.test.skip"=true>
2. Download corenlp 4.5.8 https://stanfordnlp.github.io/CoreNLP/download.html -> extract stanford-corenlp-4.5.8-models.jar to working dir
also add protobuf-java-3.25.5.jar to the path stated in the proguard config file (change the path)
3. MAYBE run <$env:CLASSPATH = $env:CLASSPATH + ";D:\MasterThesis\standfordNLPtest\CoreNLP\target\stanford-corenlp-4.5.8\*">, but im not sure if it's needed.
4. Create input.txt in working dir with some english text.
5. run <java -cp "stanford-corenlp-4.5.8-models.jar;target\*" edu.stanford.nlp.pipeline.StanfordCoreNLP -annotators tokenize,pos,depparse -file input.txt -outputFormat conll -output.columns word>
you should then get the output file called "input.txt.conll"

Note: The target artifact has to be in the location of the path "target\*" or the path has to be changed. Also, maven-shade-plugin was added to the pom file to make the program comparable to the other SUTs.

You can also run an artifact like this:
java -cp "stanford-corenlp-4.5.8-models.jar;artifacts\artifact_vanilla.jar" edu.stanford.nlp.pipeline.StanfordCoreNLP -annotators tokenize,pos,depparse -file input.txt -outputFormat conll -output.columns word

jlink:
run: jlink --compress=2 --strip-debug --no-header-files --no-man-pages --add-modules java.base,java.compiler,java.datatransfer,java.desktop,java.logging,java.management,java.prefs,java.sql,java.xml --output jlink-runtime

Depclean:
run the depclean command: mvn -f pom.xml se.kth.castor:depclean-maven-plugin:2.0.6:depclean -DcreatePomDebloated=true -DignoreDependencies="org.slf4j:slf4j-api:jar:1.7.12"
and then run 'mvn -f pom-depclean-debloated.xml clean package -DskipTests'

Deptrim:
run: mvn -f pom.xml se.kth.castor:deptrim-maven-plugin:0.1.2:deptrim -DcreateSinglePomSpecialized=true -DskipTests
and then run: mvn -f pom-deptrim-specialized.xml clean package -DskipTests
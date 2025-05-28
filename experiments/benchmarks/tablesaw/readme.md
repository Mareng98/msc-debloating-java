Note: Deptrim wrongly specialized icu4j v74.2, so it had to be deleted from the pom-deptrim-specialized pom file to allow for building. Run mvn -f pom-deptrim-specialized.xml clean install after removing it, and replace the deptrim artifact in artifacts with the one in target.

The following libraries had to be ignored by depclean because it misclassified them:
it.unimi.dsi:fastutil:8.5.13:compile,io.github.classgraph:classgraph:4.8.168:compile,com.univocity:univocity-parsers:2.9.1:compile,org.slf4j:slf4j-api:2.0.12:compile

The following libraries had to be ignored by deptrim because it misclassified them:
it.unimi.dsi:fastutil:8.5.13:compile,tech.tablesaw:tablesaw-core:0.44.1:compile
#!/bin/bash

# Enable error handling
set -e

# Set environment variables
export PROJECT_DIR=$(pwd)
export VANILLA_JAR_NAME="artifact_vanilla.jar"
export DEPTRIM_JAR_NAME="artifact_deptrim.jar"
export DEPCLEAN_JAR_NAME="artifact_depclean.jar"
export PROGUARD_JAR_NAME="artifact_proguard.jar"
export ARTIFACTS_FOLDER="$PROJECT_DIR/artifacts"
export VANILLA_JAR="$ARTIFACTS_FOLDER/$VANILLA_JAR_NAME"
export DEPTRIM_JAR="$ARTIFACTS_FOLDER/$DEPTRIM_JAR_NAME"
export DEPCLEAN_JAR="$ARTIFACTS_FOLDER/$DEPCLEAN_JAR_NAME"
export PROGUARD_JAR="$ARTIFACTS_FOLDER/$PROGUARD_JAR_NAME"
export JLINK_RUNTIME_DIR="$ARTIFACTS_FOLDER/jlink-runtime"
export TARGET_JAR_NAME="artifact.jar"
export TARGET_JAR="$PROJECT_DIR/target/$TARGET_JAR_NAME"
export PROGUARD_CONFIG="$PROJECT_DIR/proguard.pro"
export DEPTRIM_POM="$PROJECT_DIR/pom-deptrim.xml"
export DEPTRIM_SPECIALIZED_POM="$PROJECT_DIR/pom-deptrim-specialized.xml"
export DEPCLEAN_DEBLOATED_POM="$PROJECT_DIR/pom-debloated.xml"
export DEPCLEAN_POM="$PROJECT_DIR/pom-depclean.xml"
export POM="$PROJECT_DIR/pom.xml"

# 0. Ensure artifacts folder exists
echo "0. Ensure artifacts folder exists"
if [ ! -d "$ARTIFACTS_FOLDER" ]; then
    echo "Creating artifacts directory at $ARTIFACTS_FOLDER"
    mkdir -p "$ARTIFACTS_FOLDER"
fi

# Setup vanilla
echo "1. Building vanilla jar"
mvn clean install

echo "2. Renaming resulting jar in target to $VANILLA_JAR_NAME"
mv "$TARGET_JAR" "$VANILLA_JAR_NAME"

echo "3. Moving vanilla jar to artifacts folder"
mv "$VANILLA_JAR_NAME" "$ARTIFACTS_FOLDER"

echo "4. Cleaning up target folder"
rm -rf "$PROJECT_DIR/target"

# Setup jlink
echo "1. Extracting required modules for jlink"
jdeps --ignore-missing-deps --list-deps "$VANILLA_JAR" > modules.txt

# Parse modules and join them into a single string
MODULES=""

while IFS= read -r line; do
    # Trim leading and trailing spaces from each line
    line=$(echo "$line" | xargs)

    # Only append to MODULES if the line isn't empty
    if [ -n "$line" ]; then
        if [ -n "$MODULES" ]; then
            MODULES+=","
        fi
        MODULES+="$line"
    fi
done < modules.txt
echo "Identified modules: $MODULES"

echo "2. Creating jlink runtime image"

# Check if the directory exists before creating it
if [ ! -d "$ARTIFACTS_FOLDER/jlink-runtime" ]; then
    jlink --compress=2 --strip-debug --no-header-files --no-man-pages --module-path "$JAVA_HOME/jmods" --add-modules "$MODULES" --output "$JLINK_RUNTIME_DIR"

else
    echo "Directory jlink-runtime already exists, skipping creation."
fi

# Setup depclean
echo "1. Generating pom-debloated.xml with depclean"
mvn se.kth.castor:depclean-maven-plugin:2.0.6:depclean -DcreatePomDebloated=true -DignoreDependencies="org.slf4j.*"

echo "2. Renaming pom-debloated.xml to pom-depclean.xml"
mv "$PROJECT_DIR/pom-debloated.xml" "$PROJECT_DIR/pom-depclean.xml"

echo "3. Running pom-depclean.xml to build artifact"
mvn -f "$DEPCLEAN_POM" clean install

echo "4. Renaming resulting jar in target to $DEPCLEAN_JAR_NAME"
mv "$TARGET_JAR" "$DEPCLEAN_JAR_NAME"

echo "5. Moving depclean jar to artifacts folder"
mv "$DEPCLEAN_JAR_NAME" "$ARTIFACTS_FOLDER"

echo "6. Cleaning up target folder"
rm -rf "$PROJECT_DIR/target"

# Setup deptrim
echo "SETTING UP DEPTRIM"
echo "1. Creating pom-deptrim.xml from pom.xml"
cp "$POM" "$DEPTRIM_POM"
xmlstarlet ed -L -N maven="http://maven.apache.org/POM/4.0.0" \
  -s "/maven:project/maven:build/maven:plugins" \
  -t elem -n "plugin" \
  -v "" \
  -s "/maven:project/maven:build/maven:plugins/plugin[last()]" -t elem -n "groupId" -v "se.kth.castor" \
  -s "/maven:project/maven:build/maven:plugins/plugin[last()]" -t elem -n "artifactId" -v "deptrim-maven-plugin" \
  -s "/maven:project/maven:build/maven:plugins/plugin[last()]" -t elem -n "version" -v "0.1.2" \
  -s "/maven:project/maven:build/maven:plugins/plugin[last()]" -t elem -n "executions" \
  -s "/maven:project/maven:build/maven:plugins/plugin[last()]/executions" -t elem -n "execution" \
  -s "/maven:project/maven:build/maven:plugins/plugin[last()]/executions/execution" -t elem -n "phase" -v "package" \
  -s "/maven:project/maven:build/maven:plugins/plugin[last()]/executions/execution" -t elem -n "goals" \
  -s "/maven:project/maven:build/maven:plugins/plugin[last()]/executions/execution/goals" -t elem -n "goal" -v "deptrim" \
  -s "/maven:project/maven:build/maven:plugins/plugin[last()]/executions/execution" -t elem -n "configuration" \
  -s "/maven:project/maven:build/maven:plugins/plugin[last()]/executions/execution/configuration" -t elem -n "createSinglePomSpecialized" -v "true" \
  "$DEPTRIM_POM"

echo "2. Running deptrim with modified pom-deptrim.xml"
mvn -f "$DEPTRIM_POM" clean install

echo "3. Removing deptrim's pom-debloated.xml and pom-deptrim.xml"
rm -f "$PROJECT_DIR/pom-debloated.xml" "$PROJECT_DIR/pom-deptrim.xml"

echo "4. Renaming generated pom-specialized.xml to pom-deptrim-specialized.xml"
mv "$PROJECT_DIR/pom-specialized.xml" "$DEPTRIM_SPECIALIZED_POM"

echo "5. Cleaning up deptrim plugin from pom-deptrim-specialized.xml"
xmlstarlet ed -L -d "/project/build/plugins/plugin[artifactId='deptrim-maven-plugin']" "$DEPTRIM_SPECIALIZED_POM"

echo "6. Running pom-deptrim-specialized.xml"
mvn -f "$DEPTRIM_SPECIALIZED_POM" clean install

echo "7. Renaming resulting jar in target to $DEPTRIM_JAR_NAME"
mv "$TARGET_JAR" "$DEPTRIM_JAR_NAME"

echo "8. Moving deptrim jar to artifacts folder"
mv "$DEPTRIM_JAR_NAME" "$ARTIFACTS_FOLDER"

echo "9. Cleaning up target folder"
rm -rf "$PROJECT_DIR/target"

echo "Process completed."

echo "SETTING UP PROGUARD"
echo "1. Build original jar"
mvn clean install
echo "2. Debloat with proguard"
java -jar "$PROGUARD_HOME/proguard.jar" @"$PROJECT_DIR/proguard.pro"
#echo "Press any key to continue..."
#read -n 1 -s  # Waits for a single key press

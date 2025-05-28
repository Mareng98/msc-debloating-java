@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

REM Automatically set the PROJECT_DIR to the directory where the script is executed
SET PROJECT_DIR=%CD%

REM Set names of artifacts
SET VANILLA_JAR_NAME=artifact_vanilla.jar
SET DEPTRIM_JAR_NAME=artifact_deptrim.jar
SET DEPCLEAN_JAR_NAME=artifact_depclean.jar
SET PROGUARD_JAR_NAME=artifact_proguard.jar

REM Set paths to artifacts
SET ARTIFACTS_FOLDER=%PROJECT_DIR%\artifacts
SET VANILLA_JAR=%ARTIFACTS_FOLDER%\%VANILLA_JAR_NAME%
SET DEPTRIM_JAR=%ARTIFACTS_FOLDER%\%DEPTRIM_JAR_NAME%
SET DEPCLEAN_JAR=%ARTIFACTS_FOLDER%\%DEPCLEAN_JAR_NAME%
SET PROGUARD_JAR=%ARTIFACTS_FOLDER%\%PROGUARD_JAR_NAME%
SET JLINK_RUNTIME_DIR=%ARTIFACTS_FOLDER%\jlink-runtime
SET TARGET_JAR_NAME=artifact.jar
SET TARGET_JAR=%PROJECT_DIR%\target\%TARGET_JAR_NAME%

REM Set paths to config files
SET PROGUARD_CONFIG=%PROJECT_DIR%\proguard.pro
SET DEPTRIM_POM=%PROJECT_DIR%\pom-deptrim.xml
SET DEPTRIM_SPECIALIZED_POM=%PROJECT_DIR%\pom-deptrim-specialized.xml
SET DEPTRIM_DEBLOATED_POM=%PROJECT_DIR%\pom-deptrim-debloated.xml
SET DEPCLEAN_DEBLOATED_POM=%PROJECT_DIR%\pom-debloated.xml
SET DEPCLEAN_POM=%PROJECT_DIR%\pom-depclean.xml
SET POM=%PROJECT_DIR%\pom.xml

REM Setup vanilla
echo 1. Building vanilla jar
call mvn clean install

echo 2. Renaming resulting jar in target to %VANILLA_JAR_NAME%
REN "%TARGET_JAR%" "%VANILLA_JAR_NAME%"

echo 3. Moving vanilla jar to artifacts folder
MOVE "%PROJECT_DIR%\target\%VANILLA_JAR_NAME%" "%ARTIFACTS_FOLDER%"

echo 4. Cleaning up target folder
RMDIR /S /Q "%PROJECT_DIR%\target"

REM Setup jlink
echo 1. Extracting required modules for jlink
jdeps --ignore-missing-deps --list-deps "%VANILLA_JAR%" > modules.txt

SET MODULES=
for /F "tokens=*" %%i in (modules.txt) do (
    if NOT "!MODULES!"=="" (
        SET MODULES=!MODULES!,%%i
    ) else (
        SET MODULES=%%i
    )
)

del modules.txt

echo Identified modules: %MODULES%

echo 2. Creating jlink runtime image
call jlink --compress=2 --strip-debug --no-header-files --no-man-pages --module-path "%JAVA_HOME%\jmods" --add-modules %MODULES% --output "%JLINK_RUNTIME_DIR%"

REM Setup depclean
echo 1. Generating pom-debloated.xml with depclean
call mvn se.kth.castor:depclean-maven-plugin:2.0.6:depclean -DcreatePomDebloated=true -DignoreDependencies="org.yaml:snakeyaml:1.23:compile,org.apache.*"

echo 2. Renaming pom-debloated.xml to pom-depclean.xml
REN "%PROJECT_DIR%\pom-debloated.xml" pom-depclean.xml

echo 3. Running pom-depclean.xml to build artifact
call mvn -f "%DEPCLEAN_POM%" clean install

echo 4. Renaming resulting jar in target to %DEPCLEAN_JAR_NAME%
REN "%TARGET_JAR%" "%DEPCLEAN_JAR_NAME%"

echo 5. Moving depclean jar to artifacts folder
MOVE "%PROJECT_DIR%\target\%DEPCLEAN_JAR_NAME%" "%ARTIFACTS_FOLDER%"

echo 6. Cleaning up target folder
RMDIR /S /Q "%PROJECT_DIR%\target"

REM Setup deptrim
echo SETTING UP DEPTRIM
echo 1. Creating pom-deptrim-specialized.xml from pom.xml
call mvn se.kth.castor:deptrim-maven-plugin:0.1.2:deptrim -DcreateSinglePomSpecialized=true -DignoreDependencies="org.yaml:snakeyaml:1.23:compile,org.apache.commons:commons-lang3"

echo 2. Renaming generated pom-debloated.xml to pom-deptrim-debloated.xml
REN "%PROJECT_DIR%\pom-debloated.xml" "pom-deptrim-debloated.xml"

echo 4. Running pom-deptrim-debloated.xml
call mvn -f "%DEPTRIM_DEBLOATED_POM%" clean install

echo 5. Renaming resulting jar in target to %DEPTRIM_JAR_NAME%
REN "%TARGET_JAR%" "%DEPTRIM_JAR_NAME%"

echo 6. Moving deptrim jar to artifacts folder
MOVE "%PROJECT_DIR%\target\%DEPTRIM_JAR_NAME%" "%ARTIFACTS_FOLDER%"

echo 7. Cleaning up target folder
RMDIR /S /Q "%PROJECT_DIR%\target"

pause
cmd /k

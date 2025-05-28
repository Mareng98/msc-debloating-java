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
call mvn se.kth.castor:depclean-maven-plugin:2.0.6:depclean -DcreatePomDebloated=true -DignoreDependencies="org.apache.jena.*,org.apache.thrift.*,org.apache.commons.*,com.github.*"

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
echo 1. Creating pom-deptrim.xml from pom.xml
COPY "%POM%" "%DEPTRIM_POM%"

REM Insert deptrim plugin inside <build><plugins>...</plugins> (Single Line)
powershell -Command "& {$pomFile='!DEPTRIM_POM!'; $xml=[xml](Get-Content $pomFile); $ns=$xml.DocumentElement.NamespaceURI; if(-not $xml.project.build){$build=$xml.CreateElement('build', $ns);$xml.project.AppendChild($build)|Out-Null}; if(-not $xml.project.build.plugins){$plugins=$xml.CreateElement('plugins', $ns);$xml.project.build.AppendChild($plugins)|Out-Null}; $plugin=$xml.CreateElement('plugin', $ns); $groupId=$xml.CreateElement('groupId', $ns);$groupId.InnerText='se.kth.castor'; $artifactId=$xml.CreateElement('artifactId', $ns);$artifactId.InnerText='deptrim-maven-plugin'; $version=$xml.CreateElement('version', $ns);$version.InnerText='0.1.2'; $execution=$xml.CreateElement('execution', $ns); $goals=$xml.CreateElement('goals', $ns); $goal=$xml.CreateElement('goal', $ns);$goal.InnerText='deptrim'; $goals.AppendChild($goal)|Out-Null; $configuration=$xml.CreateElement('configuration', $ns); $singlePom=$xml.CreateElement('createSinglePomSpecialized', $ns); $singlePom.InnerText='true'; $configuration.AppendChild($singlePom)|Out-Null; $execution.AppendChild($goals)|Out-Null; $execution.AppendChild($configuration)|Out-Null; $executions=$xml.CreateElement('executions', $ns); $executions.AppendChild($execution)|Out-Null; $plugin.AppendChild($groupId)|Out-Null; $plugin.AppendChild($artifactId)|Out-Null; $plugin.AppendChild($version)|Out-Null; $plugin.AppendChild($executions)|Out-Null; $xml.project.build.plugins.AppendChild($plugin)|Out-Null; $xml.Save($pomFile)}"

echo 2. Running deptrim with modified pom-deptrim.xml
call mvn -f "%DEPTRIM_POM%" clean install

echo 3. Renaming generated pom-specialized.xml to pom-deptrim-specialized.xml
REN "%PROJECT_DIR%\pom-specialized.xml" "pom-deptrim-specialized.xml"

echo 4. Cleaning up deptrim plugin from pom-deptrim-specialized.xml
powershell -Command "& {$pomFile='!PROJECT_DIR!\pom-deptrim-specialized.xml'; $xml=[xml](Get-Content $pomFile); $plugins=$xml.project.build.plugins; $pluginToRemove=$plugins.plugin | Where-Object { $_.artifactId -eq 'deptrim-maven-plugin' }; if ($pluginToRemove) {$plugins.RemoveChild($pluginToRemove)|Out-Null}; $xml.Save($pomFile)}"

echo 5. Running pom-deptrim-specialized.xml
call mvn -f "%DEPTRIM_SPECIALIZED_POM%" clean install

echo 6. Renaming resulting jar in target to %DEPTRIM_JAR_NAME%
REN "%TARGET_JAR%" "%DEPTRIM_JAR_NAME%"

echo 7. Moving deptrim jar to artifacts folder
MOVE "%PROJECT_DIR%\target\%DEPTRIM_JAR_NAME%" "%ARTIFACTS_FOLDER%"

echo 8. Cleaning up target folder
RMDIR /S /Q "%PROJECT_DIR%\target"

pause
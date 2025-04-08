Note: The jlink command in the script doesn't work, generate jlink-runtime manually instead with:
jlink --compress=2 --strip-debug --no-header-files --no-man-pages --add-modules java.base,java.compiler,java.desktop,java.logging,java.sql,java.xml,jdk.unsupported --output artifacts/jlink-runtime

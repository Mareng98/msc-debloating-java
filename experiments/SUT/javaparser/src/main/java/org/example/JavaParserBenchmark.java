package org.example;

import com.github.javaparser.JavaParser;
import com.github.javaparser.ParseResult;
import com.github.javaparser.ParserConfiguration;
import com.github.javaparser.ast.CompilationUnit;
import com.github.javaparser.ast.body.MethodDeclaration;
import com.github.javaparser.ast.stmt.BlockStmt;
import com.github.javaparser.ast.stmt.ExpressionStmt;
import com.github.javaparser.ast.expr.MethodCallExpr;

import com.github.javaparser.symbolsolver.JavaSymbolSolver;

import com.github.javaparser.symbolsolver.resolution.typesolvers.CombinedTypeSolver;
import com.github.javaparser.symbolsolver.resolution.typesolvers.ReflectionTypeSolver;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.*;

public class JavaParserBenchmark implements BenchmarkTask {

    private final int iterations;
    private final List<CompilationUnit> parsedUnits = new ArrayList<>();
    private String mockData;
    private final Random random = new Random();

    private JavaParser parser;

    public JavaParserBenchmark(int iterations) {
        this.iterations = iterations;
    }

    @Override
    public void setup() {
        // Setup java parser
        CombinedTypeSolver typeSolver = new CombinedTypeSolver(new ReflectionTypeSolver());
        JavaSymbolSolver symbolSolver = new JavaSymbolSolver(typeSolver);
        ParserConfiguration config = new ParserConfiguration().setSymbolResolver(symbolSolver);
        parser = new JavaParser(config);

        // Load the mock java code from resources
        try (InputStream input = getClass().getClassLoader().getResourceAsStream("generatedJavaCode.java")) {
            if (input == null) {
                throw new RuntimeException("Resource not found: generatedJavaCode.java");
            }
            mockData = new String(input.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RuntimeException("Failed to load resource: generatedJavaCode.java", e);
        }
    }

    @Override
    public void executeIteration(int iteration) {
        // Parse the mock java code
        ParseResult<CompilationUnit> result = parser.parse(mockData);
        result.getResult().ifPresent(cu -> {
            parsedUnits.clear(); // Clear it from the previous iteration so it doesn't grow indefinitely
            parsedUnits.add(cu);

            // Try resolving all methods and their return types, and edit the methods one by one
            cu.findAll(MethodDeclaration.class).forEach(m -> {
                try {
                    var resolved = m.resolve();
                    resolved.getReturnType();
                    resolved.declaringType();
                } catch (Exception ignored) {
                    // Skip resolution errors
                }
                // Create a line of code and put it into the new body that will replace the old method body
                BlockStmt newBody = new BlockStmt();
                newBody.addStatement(
                        new ExpressionStmt(
                                new MethodCallExpr("System.out.println")
                                        .addArgument("\"Modified by benchmark\"")
                        )
                );

                // Perform some checks of return type and replace it with default value for int: 0
                if (!m.getType().isVoidType()) {
                    if (m.getType().asString().equals("int")){
                        newBody.addStatement("return 0;");
                    }
                }
                // Replace the old method body with the new one
                m.setBody(newBody);
            });
        });
    }
    @Override
    public void writeResult() {
        // Write the result to a file to be compared to later
        try (BufferedWriter writer = new BufferedWriter(new FileWriter("output_" + getName() + ".txt"))) {
            writer.write(parsedUnits.toString());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public boolean cleanupAndVerify() {
        try {
            // Read the content of the output file and ensure it's the same as the modified parsed code
            String fileContent = Files.readString(Paths.get("output_" + getName() + ".txt"));
            return fileContent.equals(parsedUnits.toString());
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public String getName() {
        return "JavaParserBenchmark";
    }

    // This was used to generate the java code that would be parsed
    private String generateFakeJavaClass(int index) {
        String className = "FakeClass" + index + "_" + random.nextInt(10000);
        String fileName = className + ".java";

        StringBuilder classBuilder = new StringBuilder();
        classBuilder.append("public class ").append(className).append(" {\n");

        // Generate multiple methods
        for (int i = 0; i < 1000; i++) {
            String methodName = "method" + i + "_" + random.nextInt(100);
            classBuilder.append("    public int ").append(methodName).append("() {\n")
                    .append("        int x = ").append(random.nextInt(100)).append(";\n")
                    .append("        return x * 2;\n")
                    .append("    }\n\n");
        }

        classBuilder.append("}");

        String classSource = classBuilder.toString();

        // Write to file
        try {
            String outputDir = "generated_classes";
            java.nio.file.Files.createDirectories(java.nio.file.Paths.get(outputDir));
            java.nio.file.Files.writeString(java.nio.file.Paths.get(outputDir, fileName), classSource);
        } catch (IOException e) {
            e.printStackTrace();
        }

        return classSource;
    }

}

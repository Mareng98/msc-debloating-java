package org.example;

import com.github.javafaker.Faker;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

public class JavaFakerBenchmark implements BenchmarkTask {
    // We set a seed so that the output is identical for the same number of iterations
    private final Faker faker = new Faker(new Random(12345));;
    private final List<String> generatedData = new ArrayList<>();
    private final int iterations;

    public JavaFakerBenchmark(int iterations) {
        this.iterations = iterations;
    }

    @Override
    public void setup() {
    }

    @Override
    public void executeIteration(int iteration) {
        String name = faker.name().fullName();
        String address = faker.address().fullAddress();
        String phoneNumber = faker.phoneNumber().phoneNumber();
        String company = faker.company().name();
        String paragraph = String.join(" ", faker.lorem().paragraphs(5));
        String creditCard = faker.finance().creditCard();
        String avatar = faker.avatar().image();
        String shakespeareQuote = faker.shakespeare().hamletQuote();

        String record = String.format(
                "%d: %s, %s, %s, %s, %s, %s, %s, %s",
                iteration, name, address, phoneNumber, company, paragraph, creditCard, avatar, shakespeareQuote
        );
        generatedData.add(record);
    }

    @Override
    public void writeResult() {
        try (FileWriter writer = new FileWriter("output_"+getName()+".txt")) {
            for (String data : generatedData) {
                writer.write(data + "\n");
            }
            System.out.println("Results written to " + "output_"+getName()+".txt");
        } catch (IOException e) {
            System.err.println("Error writing results: " + e.getMessage());
        }
    }

    @Override
    public boolean cleanupAndVerify() {
        try {
            List<String> fileData = Files.lines(Paths.get("output_"+getName()+".txt")).collect(Collectors.toList());
            return generatedData.equals(fileData);
        } catch (IOException e) {
            System.err.println("Error reading results file: " + e.getMessage());
            return false;
        }
    }

    @Override
    public String getName() {
        return "JavaFakerBenchmark";
    }
}

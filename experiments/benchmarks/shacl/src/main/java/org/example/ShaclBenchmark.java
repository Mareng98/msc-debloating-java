package org.example;

import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.riot.RDFDataMgr;
import org.apache.jena.riot.RDFLanguages;
import org.topbraid.shacl.vocabulary.SH;
import org.topbraid.shacl.validation.ValidationUtil;

import java.io.*;
import java.util.ArrayList;
import java.util.List;

public class ShaclBenchmark implements BenchmarkTask{

    private final int iterations;
    public ShaclBenchmark(int iterations){
        this.iterations = iterations;
    }
    private static Model dataModel;
    private static Model shapesModel;
    private static Resource validationReport;
    @Override
    public void setup() {
        // Load RDF data file (data.ttl)
        dataModel = ModelFactory.createDefaultModel();
        RDFDataMgr.read(dataModel, "data.ttl", RDFLanguages.TTL);

        // Load SHACL shapes file (shapes.ttl)
        shapesModel = ModelFactory.createDefaultModel();
        RDFDataMgr.read(shapesModel, "shapes.ttl", RDFLanguages.TTL);
    }

    @Override
    public void executeIteration(int iteration) {
        // Run SHACL validation with shapes on data
        validationReport = ValidationUtil.validateModel(dataModel, shapesModel, true);
    }

    private String getViolationReport(){
        Model resultModel = validationReport.getModel();
        List<String> violations = new ArrayList<>();
        // Find violations
        resultModel.listStatements(null, SH.resultSeverity, SH.Violation)
                .forEachRemaining(statement -> {
                    Resource violation = statement.getSubject();

                    // Add violation message
                    RDFNode messageNode = violation.getProperty(SH.resultMessage) != null ? violation.getProperty(SH.resultMessage).getObject() : null;
                    if (messageNode != null){
                        violations.add(messageNode.toString());
                    }

                    // Add reference to which node the violation pertains to
                    RDFNode focusNode = violation.getProperty(SH.focusNode) != null ? violation.getProperty(SH.focusNode).getObject() : null;
                    if (focusNode != null) {
                        violations.add(focusNode.toString());
                    }

                });
        return violations.toString();
    }
    @Override
    public void writeResult() {
        String violationsMessage = getViolationReport();
        File resultFile = new File("output_" + getName() + ".txt");

        try (BufferedWriter writer = new BufferedWriter(new FileWriter(resultFile))) {
            // Write violations to file
            writer.write(violationsMessage);
            System.out.println("Violation report written to: " + resultFile.getAbsolutePath());
        } catch (Exception e) {
            throw new RuntimeException("Error writing violation report to file", e);
        }

    }

    @Override
    public boolean cleanupAndVerify() {
        String violationsMessage = getViolationReport();
        BufferedReader reader;
        try {
            reader = new BufferedReader(new FileReader("output_"+getName()+".txt"));
            String line = reader.readLine();

            if(line.equals(violationsMessage)){
                return true;
            }

            reader.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return false;
    }

    @Override
    public String getName() {
        return "ShaclBenchmark";
    }
}
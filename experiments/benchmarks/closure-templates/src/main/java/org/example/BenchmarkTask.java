package org.example;
public interface BenchmarkTask {
    /**
     * Prepare any resources or input data needed by the benchmark.
     */
    void setup();

    /**
     * Execute a single iteration of the benchmark.
     * @param iteration The current iteration number.
     */
    void executeIteration(int iteration);

    /**
     * If the output can be written to a file, write the output to a file.
     * This file is intended to be used for verifying the correctness of execution for new runs.
     */
    void writeResult();

    /**
     * Clean up resources and perform any final verification of output.
     */
    boolean cleanupAndVerify();

    /**
     * Provide a name for the benchmark.
     * @return the benchmark's class name in camelCase.
     */
    String getName();
}

package org.example;

public class BenchmarkRunner {
    /**
     * Runs the given benchmark for a fixed number of iterations.
     * @param task       The benchmark task to run.
     * @param iterations The number of iterations to execute.
     * @param writeResult If the result should be outputted for later comparison.
     */
    public static void runBenchmark(BenchmarkTask task, int iterations, boolean writeResult) {
        System.out.println("Starting benchmark: " + task.getName());
        task.setup();
        long startTime = System.currentTimeMillis();

        for (int i = 0; i < iterations; i++) {
            task.executeIteration(i);
        }

        long endTime = System.currentTimeMillis();
        System.out.println(task.getName() + " completed " + iterations +
                " iterations in " + (endTime - startTime) + " ms.");

        // Write the result to a file to be compared later at the end of execution
        if(writeResult){
            task.writeResult();
        }

        // Clean up any resources and verify that output is as expected
        if(task.cleanupAndVerify()){
            System.out.println("Success");
        }else{
            System.out.println("Failure");
        }

    }

    public static void main(String[] args) {
        int iterations = Integer.parseInt(args[0]);
        boolean writeResult = false;
        if (args.length > 1){
            writeResult = Boolean.parseBoolean(args[1]);
        }
        BenchmarkTask flyingSaucerBenchmark = new ShaclBenchmark(iterations);
        runBenchmark(flyingSaucerBenchmark, iterations, writeResult);
    }
}
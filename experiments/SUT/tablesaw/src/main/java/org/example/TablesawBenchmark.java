package org.example;

import tech.tablesaw.api.*;
import tech.tablesaw.io.csv.CsvReadOptions;

import java.nio.file.Path;
import java.util.stream.IntStream;

import static tech.tablesaw.aggregate.AggregateFunctions.*;

public class TablesawBenchmark implements BenchmarkTask {
    private Table table;
    private Table groupedTable;
    private final int numRows;
    private final int numCols;
    private final Path resultPath = Path.of("tablesaw_benchmark_result.csv");

    public TablesawBenchmark(int iterations) {
        this.numRows = iterations;
        this.numCols = 500;
    }

    @Override
    public void setup() {
        System.out.println("Setting up benchmark with " + numRows + " rows and " + numCols + " columns.");
        String[] columnNames = IntStream.range(0, numCols)
                .mapToObj(i -> "Column" + i)
                .toArray(String[]::new);
        table = Table.create("Benchmark Table");
        for (String colName : columnNames) {
            table.addColumns(DoubleColumn.create(colName, new double[numRows]));
        }
    }

    @Override
    public void executeIteration(int iteration) {

        // Generate new random values for the dataset
        for (int i = 0; i < numCols; i++) {
            DoubleColumn col = (DoubleColumn) table.column(i);
            col.set(iteration % numRows, iteration);
        }

        // Group by quartiles and aggregate
        groupedTable = table.summarize(table.columnNames(), mean, median, min, max).apply();
    }

    @Override
    public void writeResult() {
        groupedTable.write().csv(resultPath.toString()); // Writes the grouped table to CSV
        System.out.println("Results written to " + resultPath.toAbsolutePath());
    }

    @Override
    public boolean cleanupAndVerify() {
        // Load the previously written results
        Table loadedTable = Table.read().csv(CsvReadOptions.builder(resultPath.toString()).build());

        // Check if the number of rows and columns are the same
        if (groupedTable.rowCount() != loadedTable.rowCount() || groupedTable.columnCount() != loadedTable.columnCount()) {
            System.out.println("Row count or column count mismatch.");
            return false;
        }

        // Compare each cell in the tables
        for (int row = 0; row < groupedTable.rowCount(); row++) {
            for (int col = 0; col < groupedTable.columnCount(); col++) {
                // Get the value in each table for the current cell
                Number groupedValue = (Number) groupedTable.get(row, col);
                Number loadedValue = (Number) loadedTable.get(row, col);

                // Convert Number to double (or int, depending on the type)
                double groupedDoubleValue = groupedValue.doubleValue();
                double loadedDoubleValue = loadedValue.doubleValue();

                // Allow for some small floating-point error when comparing values
                if (Math.abs(groupedDoubleValue - loadedDoubleValue) > 1e-5) {
                    System.out.println("Mismatch found at row " + row + ", column " + col);
                    return false;
                }
            }
        }

        // If all cells match
        System.out.println("Cleanup complete. Verification: Success");
        return true;
    }


    @Override
    public String getName() {
        return "TablesawBenchmark";
    }
}

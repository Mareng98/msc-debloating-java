package org.example;

import org.locationtech.jts.algorithm.LineIntersector;
import org.locationtech.jts.algorithm.RobustLineIntersector;
import org.locationtech.jts.geom.*;
import org.locationtech.jts.io.WKTWriter;
import org.locationtech.jts.noding.*;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

public class JtsBenchmark implements BenchmarkTask {

    private final GeometryFactory geometryFactory = new GeometryFactory();
    private final List<Geometry> results = new ArrayList<>();
    private final List<Polygon> basePolygons = new ArrayList<>();
    private final int iterations;

    public JtsBenchmark(int iterations){
        this.iterations = iterations;
    }

    @Override
    public void setup() {
        // Generate a 50x20 grid of squares (1000 total), fixed coordinates
        int gridSizeX = 50;
        int gridSizeY = 20;
        double squareSize = 10.0;

        for (int x = 0; x < gridSizeX; x++) {
            for (int y = 0; y < gridSizeY; y++) {
                double minX = x * squareSize;
                double minY = y * squareSize;
                double maxX = minX + squareSize;
                double maxY = minY + squareSize;

                Coordinate[] coords = new Coordinate[]{
                        new Coordinate(minX, minY),
                        new Coordinate(minX, maxY),
                        new Coordinate(maxX, maxY),
                        new Coordinate(maxX, minY),
                        new Coordinate(minX, minY)
                };
                basePolygons.add(geometryFactory.createPolygon(coords));
            }
        }
    }

    @Override
    public void executeIteration(int iteration) {
        List<SegmentString> segments = new ArrayList<>();
        results.clear();
        int gridSize = 230; // adjust for intensity

        for (int i = 0; i < gridSize; i++) {
            for (int j = 0; j < gridSize; j++) {
                // Diagonal lines from topleft to bottom right
                Coordinate p0 = new Coordinate(i, j);
                Coordinate p1 = new Coordinate(i + 1, j + 1);
                LineString line1 = geometryFactory.createLineString(new Coordinate[]{p0, p1});
                segments.add(new NodedSegmentString(line1.getCoordinates(), null));
                // Diagonal lines from topright to bottom left
                Coordinate p2 = new Coordinate(i + 1, j);
                Coordinate p3 = new Coordinate(i, j + 1);
                LineString line2 = geometryFactory.createLineString(new Coordinate[]{p2, p3});
                segments.add(new NodedSegmentString(line2.getCoordinates(), null));
            }
        }

        // Set up a SegmentIntersector to calculate all intersections
        LineIntersector li = new RobustLineIntersector();
        SegmentIntersector intersector = new IntersectionAdder(li);

        // Perform noding (the actual calculation)
        MCIndexNoder noder = new MCIndexNoder();
        noder.setSegmentIntersector(intersector);
        noder.computeNodes(segments);

        // Get all nodes and add it to result
        Collection<?> noded = noder.getNodedSubstrings();
        List<LineString> lines = new ArrayList<>();
        for (Object obj : noded) {
            SegmentString ss = (SegmentString) obj;
            lines.add(geometryFactory.createLineString(ss.getCoordinates()));
        }

        results.add(geometryFactory.createMultiLineString(lines.toArray(new LineString[0])));
    }

    @Override
    public void writeResult() {
        // Write the intersecting nodes into a file for later comparison
        try {
            WKTWriter writer = new WKTWriter();
            java.nio.file.Path path = java.nio.file.Paths.get("jts_benchmark_output.txt");
            List<String> lines = new ArrayList<>();
            for (Geometry geom : results) {
                lines.add(writer.write(geom));
            }
            java.nio.file.Files.write(path, lines);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public boolean cleanupAndVerify() {
        // First, check that the results are valid (non-null and non-empty)
        boolean validResults = results.stream().allMatch(geom -> geom != null && !geom.isEmpty());

        if (!validResults) {
            return false;
        }

        // Read the previously written results from the file
        Path outputFilePath = Paths.get("jts_benchmark_output.txt");
        try {
            List<String> fileLines = Files.readAllLines(outputFilePath);

            // Now, create the expected output from the current results
            WKTWriter writer = new WKTWriter();
            List<String> currentLines = new ArrayList<>();
            for (Geometry geom : results) {
                currentLines.add(writer.write(geom));
            }

            // Compare the file contents with the current results
            if (fileLines.size() != currentLines.size()) {
                return false; // If the sizes don't match, they are not identical
            }
            // Ensure all lines match
            for (int i = 0; i < fileLines.size(); i++) {
                if (!fileLines.get(i).equals(currentLines.get(i))) {
                    return false;
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }

        return true;
    }

    @Override
    public String getName() {
        return "JtsBenchmark";
    }
}

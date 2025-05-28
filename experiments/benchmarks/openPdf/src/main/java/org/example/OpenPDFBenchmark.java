package org.example;

import com.lowagie.text.*;
import com.lowagie.text.pdf.*;

import java.io.ByteArrayOutputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Objects;

public class OpenPDFBenchmark implements BenchmarkTask {
    private static final String tmpFileName = "tmpPDF.pdf";
    private final int iterations;
    private static Image img;
    private static int currentPage = 1; // Tracks the current page for appending rows
    private static float currentY = 700; // Y coordinate for the next row on the current page
    private static int lastPageWithHeader = 0; // The page number where the table+image header has been added
    private static byte[] pdfBytes; // Store the PDF in memory
    public OpenPDFBenchmark(int iterations){
        this.iterations = iterations;


    }

    // Append a row "Row {iteration}" onto the current last page.
    // If there is not enough space, insert a new page and add the table and image header, and continue.
    private static void manipulatePDF(int iteration) {
        try {
            PdfReader reader = new PdfReader(pdfBytes);
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            PdfStamper stamper = new PdfStamper(reader, outputStream);

            // Check if there is enough space on the current page
            int bottomMargin = 50;
            if (currentY < bottomMargin) {
                // Not enough space on the current page, insert a new page at the end
                int newPageNum = reader.getNumberOfPages() + 1;
                stamper.insertPage(newPageNum, reader.getPageSize(1));
                currentPage = newPageNum;
                // Reset currentY for the new page
                currentY = reader.getPageSize(1).getTop() - 50;
                // Reset header flag so that the table and image will be added on this new page
                lastPageWithHeader = 0;
            }

            // Get the content of the current page
            PdfContentByte content = stamper.getOverContent(currentPage);

            // If the header (table and image) has not been added to this page, add it once.
            if (currentPage != lastPageWithHeader) {
                // Add table
                PdfPTable table = new PdfPTable(3);
                table.addCell("A1");
                table.addCell("B1");
                table.addCell("C1");
                table.addCell("A2");
                table.addCell("B2");
                table.addCell("C2");

                ColumnText ct = new ColumnText(content);
                ct.setSimpleColumn(50, 600, 500, 700);
                ct.addElement(table);
                ct.go();

                // Add image
                content.addImage(img);

                lastPageWithHeader = currentPage;
                // Set currentY to start below the header
                currentY = 450;
            }

            // Append the new row text on the current page at the current Y position
            ColumnText.showTextAligned(content, Element.ALIGN_LEFT,
                    new Phrase("Row " + iteration), 50, currentY, 0);
            currentY -= 20; // Decrease Y for the next row

            stamper.close();
            reader.close();

            pdfBytes = outputStream.toByteArray();
        } catch (Exception e) {
            System.err.println("Error modifying PDF: " + e.getMessage());
        }
    }


    @Override
    public void setup() {
        // Generate a PDF file with a single page and paragraph
        try (FileOutputStream fileOutputStream = new FileOutputStream(tmpFileName)) {
            Document document = new Document();
            PdfWriter.getInstance(document, fileOutputStream);
            document.open();
            document.add(new Paragraph("PDF Stress Test Document"));
            document.close();
        } catch (Exception e) {
            System.err.println("Error creating PDF: " + e.getMessage());
        }
        // Load PDF into memory to avoid locked file collision
        try{
            pdfBytes = java.nio.file.Files.readAllBytes(java.nio.file.Paths.get(tmpFileName));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        // Load image to add to pdf
        try{
            img = Image.getInstance(Objects.requireNonNull(
                    OpenPDFBenchmark.class.getClassLoader().getResource("testImage.jpg")));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        img.setAbsolutePosition(200, 500);
        img.scaleToFit(150, 150);
}

    @Override
    public void executeIteration(int iteration) {
        manipulatePDF(iteration);
    }

    @Override
    public void writeResult() {
        // Output the final rendered pdf to a PDF file
        try (FileOutputStream fos = new FileOutputStream("output_" + getName() + ".pdf")) {
            fos.write(pdfBytes);
            System.out.println("Wrote output to: " + "output_" + getName() + ".pdf");
        } catch (IOException e) {
            System.err.println("Error writing output for" + getName() + ": " + e.getMessage());
        }
    }

    @Override
    public boolean cleanupAndVerify() {
        // Load PDF into memory to avoid locked file collision
        byte[] correctOutput;
        try{
            correctOutput = java.nio.file.Files.readAllBytes(java.nio.file.Paths.get("output_" + getName() + ".pdf"));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        // Verify the first 95% of the bytes,
        // the remaining 5% at the end of the file might differ due to metadata such as timestamps
        int correctOutputWithoutMetadataLength = (int) (correctOutput.length*0.95);
        int pdfBytesWithoutMetadataLength = (int) (pdfBytes.length*0.95);
        byte[] correctOutputWithoutMetadata = Arrays.copyOfRange(correctOutput, 0, correctOutputWithoutMetadataLength);
        byte[] pdfBytesWithoutMetadata = Arrays.copyOfRange(pdfBytes, 0, pdfBytesWithoutMetadataLength);
        // Delete temporary file
        try{
            java.nio.file.Files.delete(Path.of(tmpFileName));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        // Return comparison of correct pdf and current pdf
        return java.util.Arrays.equals(correctOutputWithoutMetadata, pdfBytesWithoutMetadata);
    }

    @Override
    public String getName() {
        return "OpenPDFBenchmark";
    }
}

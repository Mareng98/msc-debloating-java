package org.example;

import com.lowagie.text.Document;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Image;
import com.lowagie.text.Element;
import com.lowagie.text.Phrase;
//import com.lowagie.text.pdf.PdfContentByte;
//import com.lowagie.text.pdf.PdfReader;
//import com.lowagie.text.pdf.PdfStamper;
//import com.lowagie.text.pdf.PdfWriter;
import com.lowagie.text.pdf.*;

import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Objects;

public class Main {
    private static final int NUM_OF_ITERATIONS = 1000;
    public static void main(String[] args) throws IOException {

        for (int i = 0; i < NUM_OF_ITERATIONS; i++) {
            String fileName = "testPDF.pdf";
            createPDF(fileName);
            manipulatePDF(fileName);
            rotatePage(fileName);
        }
    }

    // Step 1: Create a simple PDF with a title
    private static void createPDF(String fileName) {
        try (FileOutputStream fileOutputStream = new FileOutputStream(fileName)) {
            Document document = new Document();
            PdfWriter.getInstance(document, fileOutputStream);
            document.open();
            document.add(new Paragraph("PDF Stress Test Document"));
            document.close();
            System.out.println("Created: " + fileName);
        } catch (Exception e) {
            System.err.println("Error creating PDF: " + e.getMessage());
        }
    }


    // Step 2: Add a table, an image, and a new page with text
    private static void manipulatePDF(String fileName) throws IOException {
        // Load into memory to avoid locked file collision
        byte[] pdfBytes = java.nio.file.Files.readAllBytes(java.nio.file.Paths.get(fileName));

        try (PdfReader reader = new PdfReader(pdfBytes);
             FileOutputStream fileOutputStream = new FileOutputStream(fileName);
             PdfStamper stamper = new PdfStamper(reader, fileOutputStream)){

            PdfContentByte content = stamper.getOverContent(1);

            // Add a table
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

            // Add an image
            Image img = Image.getInstance(Objects.requireNonNull(Main.class.getClassLoader().getResource("testImage.jpg")));
            img.setAbsolutePosition(200, 500);
            img.scaleToFit(150, 150);
            content.addImage(img);

            // Add a new page with text
            stamper.insertPage(2, reader.getPageSize(1));
            PdfContentByte newPage = stamper.getOverContent(2);
            ColumnText.showTextAligned(newPage, Element.ALIGN_CENTER, new Phrase("This is a new page"), 250, 500, 0);
            System.out.println("Modified: " + fileName);

        } catch (Exception e) {
            System.err.println("Error modifying PDF: " + e.getMessage());
        }
    }


    // Step 3: Rotate the first page
    private static void rotatePage(String fileName) throws IOException {
        // Load into memory to avoid locked file collision
        byte[] pdfBytes = java.nio.file.Files.readAllBytes(java.nio.file.Paths.get(fileName));
        try (PdfReader reader = new PdfReader(pdfBytes);
             FileOutputStream fileOutputStream = new FileOutputStream(fileName);
             PdfStamper stamper = new PdfStamper(reader, fileOutputStream)) {

            int pageRotation = (reader.getPageRotation(1) + 90) % 360;
            reader.getPageN(1).put(PdfName.ROTATE, new PdfNumber(pageRotation));

            System.out.println("Rotated Page: " + fileName);
        } catch (Exception e) {
            System.err.println("Error rotating page: " + e.getMessage());
        }
    }
}

package org.example;

import org.xhtmlrenderer.resource.XMLResource;
import org.xhtmlrenderer.swing.Java2DRenderer;
import org.w3c.dom.Document;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.nio.charset.StandardCharsets;

public class FlyingSaucerBenchmark implements BenchmarkTask {
    private String xhtmlContent;
    private final int renderWidth = 1024;
    private final int renderHeight = 768;
    private final int iterations;
    private BufferedImage finalImage;

    public FlyingSaucerBenchmark(int iterations){
        this.iterations = iterations;
    }
    @Override
    public String getName() {
        return "FlyingSaucerBenchmark";
    }

    @Override
    public void setup() {
        // Build a complex CSS string to increase processing work.
        StringBuilder complexCSS = new StringBuilder();
        complexCSS.append("body { font-family: Arial, sans-serif; background-color: #f0f0f0; margin: 0; padding: 20px; }");
        complexCSS.append("h1, h2, h3, h4, h5, h6 { color: #333333; text-align: center; }");
        complexCSS.append("p { margin: 10px 0; padding: 10px; border: 1px solid #ccc; }");
        complexCSS.append("div.container { width: 90%; margin: auto; }");
        complexCSS.append("div.box { border: 2px solid #666; padding: 20px; margin: 10px; background: linear-gradient(45deg, #f06, transparent); }");
        complexCSS.append("ul.list { list-style-type: none; margin: 0; padding: 0; }");
        complexCSS.append("ul.list li { padding: 5px; margin: 2px 0; background: #ddd; }");
        complexCSS.append("table.complex { width: 100%; border-collapse: collapse; }");
        complexCSS.append("table.complex th, table.complex td { border: 1px solid #999; padding: 5px; text-align: center; }");
        complexCSS.append("@media screen and (max-width: 800px) { body { background-color: #e0e0e0; } div.container { width: 100%; } }");

        // Append many repetitive and nested CSS rules to further increase complexity.
        for (int i = 0; i < 100; i++) {
            complexCSS.append(String.format(
                    ".complex%d { border: %dpx solid #%06x; padding: %dpx; margin: %dpx; background-color: #%06x; }",
                    i, (i % 5) + 1, (i * 123456) & 0xffffff, i * 2, i * 3, ((i + 1) * 654321) & 0xffffff));
        }

        // Assemble the XHTML content with the complex CSS.
        xhtmlContent = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
                "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" " +
                "\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n" +
                "<html xmlns=\"http://www.w3.org/1999/xhtml\">\n" +
                "  <head>\n" +
                "    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n" +
                "    <title>CSS Rendering Stress Test</title>\n" +
                "    <style type=\"text/css\">\n" +
                complexCSS.toString() +
                "    </style>\n" +
                "  </head>\n" +
                "  <body>\n" +
                "    <div class=\"container\">\n" +
                "      <h1>Test Document</h1>\n" +
                "      <div class=\"box\">\n" +
                "         <p>This is a sample paragraph with complex CSS styling applied.</p>\n" +
                "         <p>Another paragraph to test layout and performance.</p>\n" +
                "         <ul class=\"list\">\n" +
                "             <li>List item 1</li>\n" +
                "             <li>List item 2</li>\n" +
                "             <li>List item 3</li>\n" +
                "         </ul>\n" +
                "         <table class=\"complex\">\n" +
                "             <tr><th>Header 1</th><th>Header 2</th></tr>\n" +
                "             <tr><td>Data 1</td><td>Data 2</td></tr>\n" +
                "         </table>\n" +
                "      </div>\n" +
                "    </div>\n" +
                "  </body>\n" +
                "</html>";
    }

    @Override
    public void executeIteration(int iteration) {
        try {
            ByteArrayInputStream inputStream = new ByteArrayInputStream(xhtmlContent.getBytes(StandardCharsets.UTF_8));
            Document document = XMLResource.load(inputStream).getDocument();
            document.getDocumentElement().normalize();

            Java2DRenderer renderer = new Java2DRenderer(document, renderWidth, renderHeight);
            finalImage = renderer.getImage();

        } catch (Exception e) {
            System.err.println("Error in iteration " + iteration + " (FlyingSaucerBenchmark): " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * Compares two BufferedImages pixel by pixel.
     * @param imgA the first image to compare.
     * @param imgB the second image to compare.
     * @return true if both images are identical in dimensions and pixel values; false otherwise.
     */
    public static boolean compareImages(BufferedImage imgA, BufferedImage imgB) {
        // Check if dimensions are equal
        if (imgA.getWidth() != imgB.getWidth() || imgA.getHeight() != imgB.getHeight()) {
            return false;
        }

        int width  = imgA.getWidth();
        int height = imgA.getHeight();

        // Compare pixel values
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                if (imgA.getRGB(x, y) != imgB.getRGB(x, y)) {
                    return false;
                }
            }
        }
        return true;
    }

    @Override
    public void writeResult(){
        // Output the final rendered image to a PNG file

        try {
            File outputFile = new File("output_" + getName() + ".png");
            ImageIO.write(finalImage, "png", outputFile);
            System.out.println("Wrote output to: " + outputFile.getAbsolutePath());
        } catch (Exception e) {
            System.err.println("Error writing output for" + getName() + ": " + e.getMessage());
        }

    }

    @Override
    public boolean cleanupAndVerify() {

        if (finalImage != null) {
            try {
                BufferedImage correctOutput = ImageIO.read(new File("output_" + getName() + ".png"));
                return compareImages(finalImage,correctOutput);
            } catch (Exception e) {
                System.err.println("Error reading correct output: " + e.getMessage());
                e.printStackTrace();
            }
        } else {
            System.err.println("No image was rendered in FlyingSaucerBenchmark.");
        }
        return false;
    }
}
package org.example;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.MultiFormatWriter;
import com.google.zxing.WriterException;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.LuminanceSource;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.client.j2se.BufferedImageLuminanceSource;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.common.HybridBinarizer;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.util.HashMap;
import java.util.Map;

public class ZxingBenchmark implements BenchmarkTask {
    private static String DATA = "https://www.example.com";
    private static final int SIZE = 250;
    private final int iterations;
    private String decodedData;

    private BufferedImage finalImage;
    public ZxingBenchmark(int iterations){
        this.iterations = iterations;
    }

    public void generateQRCode(int i) {
        try {
            // Create a map of encoding options
            Map<EncodeHintType, Object> hintMap = new HashMap<>();
            hintMap.put(EncodeHintType.MARGIN, 1);  // Set the margin

            // Generate the QR code matrix
            BitMatrix bitMatrix = new MultiFormatWriter().encode(DATA, BarcodeFormat.QR_CODE, SIZE, SIZE, hintMap);

            // Convert BitMatrix to BufferedImage
            BufferedImage image = new BufferedImage(SIZE, SIZE, BufferedImage.TYPE_INT_RGB);
            for (int x = 0; x < SIZE; x++) {
                for (int y = 0; y < SIZE; y++) {
                    image.setRGB(x, y, bitMatrix.get(x, y) ? 0x000000 : 0xFFFFFF);  // Set color (black/white)
                }
            }

            // Save the image
            finalImage = image;
        } catch (WriterException e) {
            e.printStackTrace();
        }
    }

    private String decodeQRCode() {
        try {
            // Read the image file
            LuminanceSource source = new BufferedImageLuminanceSource(finalImage);
            BinaryBitmap bitmap = new BinaryBitmap(new HybridBinarizer(source));

            // Create a MultiFormatReader
            MultiFormatReader reader = new MultiFormatReader();
            // Decode the barcode
            decodedData = reader.decode(bitmap).getText();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    @Override
    public void setup() {
        return;
    }

    @Override
    public void executeIteration(int iteration) {
        generateQRCode(iteration);  // Generate QR code with data "https://www.example{iteration}.com"
        decodeQRCode();    // Decode QR code and save it to finalImage
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
    public void writeResult() {
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
                // Save last decoded value
                String thisDecodedData = String.copyValueOf(decodedData.toCharArray());
                // Compare images
                boolean imagesIdentical = compareImages(finalImage,correctOutput);
                // Decode correctOutput
                finalImage = correctOutput;
                decodeQRCode();
                // Compare decoded values
                boolean decodedValuesIdentical = thisDecodedData.equals(decodedData);
                return imagesIdentical && decodedValuesIdentical;
            } catch (Exception e) {
                System.err.println("Error reading correct output: " + e.getMessage());
                e.printStackTrace();
            }
        } else {
            System.err.println("No image was rendered.");
        }
        return false;
    }

    @Override
    public String getName() {
        return "ZxingBenchmark";
    }
}
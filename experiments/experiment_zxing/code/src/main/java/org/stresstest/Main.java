package org.stresstest;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.MultiFormatWriter;
import com.google.zxing.WriterException;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.LuminanceSource;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.NotFoundException;
import com.google.zxing.client.j2se.BufferedImageLuminanceSource;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.common.HybridBinarizer;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

class StressTestQRCode {

    private static final String FILE_PATH = "qrcode.png";
    private static final String DATA = "https://www.example.com";
    private static final int SIZE = 250;

    public static void generateQRCode() {
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

            // Save the image to file
            ImageIO.write(image, "PNG", new File(FILE_PATH));
            System.out.println("QR code generated and saved to " + FILE_PATH);
        } catch (WriterException | IOException e) {
            e.printStackTrace();
        }
    }

    static void decodeQRCode() {
        try {
            // Read the image file
            BufferedImage image = ImageIO.read(new File(FILE_PATH));
            LuminanceSource source = new BufferedImageLuminanceSource(image);
            BinaryBitmap bitmap = new BinaryBitmap(new HybridBinarizer(source));

            // Create a MultiFormatReader
            MultiFormatReader reader = new MultiFormatReader();
            // Decode the barcode
            String result = reader.decode(bitmap).getText();
            System.out.println("Decoded text: " + result);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        // Stress test: Generate and decode QR codes 10 times
        for (int i = 0; i < 10000; i++) {
            System.out.println("Running test " + (i + 1) + "...");
            generateQRCode();  // Generate QR code
            decodeQRCode();    // Decode QR code
            System.out.println("-------------------------");
        }
    }
}
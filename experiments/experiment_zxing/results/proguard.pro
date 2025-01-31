-injars       stresstest.jar
-outjars      stresstest_out.jar
-libraryjars  <java.home>/jmods/java.base.jmod
-libraryjars  <java.home>/jmods/java.desktop.jmod
-libraryjars  <java.home>/jmods/java.xml.jmod


-keep class org.stresstest.StressTestQRCode {
    *;
}

# Keep required classes for ZXing (QR Code processing)
-keep public class com.google.zxing.EncodeHintType { *; }
-keep public class com.google.zxing.MultiFormatWriter { *; }
-keep public class com.google.zxing.WriterException { *; }
-keep public class com.google.zxing.BinaryBitmap { *; }
-keep public class com.google.zxing.LuminanceSource { *; }
-keep public class com.google.zxing.common.HybridBinarizer { *; }
-keep public class com.google.zxing.MultiFormatReader { *; }
-keep public class com.google.zxing.common.BitMatrix { *; }
-keep public class com.google.zxing.ResultMetadataType { *; }

# Keep ImageIO-related classes to prevent missing service providers

-keep class * extends javax.imageio.spi.IIOServiceProvider { *; }

# ProGuard optimization options
-verbose
-mergeinterfacesaggressively  # Aggressively merges interfaces (use with caution)
-optimizeaggressively  # Optimizes aggressively (might break things)
-optimizationpasses 5  # Number of optimization passes
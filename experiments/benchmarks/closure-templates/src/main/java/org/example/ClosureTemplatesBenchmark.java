package org.example;

import com.google.template.soy.SoyFileSet;
import com.google.template.soy.tofu.SoyTofu;
import com.google.template.soy.data.SoyMapData;
import com.google.template.soy.data.SoyListData;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.*;

public class ClosureTemplatesBenchmark implements BenchmarkTask {

    private final int iterations;
    private SoyTofu.Renderer renderer;
    private List<String> renderedResults = new ArrayList<>();
    private SoyMapData data;

    private List<List<String>> products;

    public ClosureTemplatesBenchmark(int iterations) {
        this.iterations = iterations;
    }

    @Override
    public void setup() {
        products = new ArrayList<>();
        for (int i = 0; i < 100000; i++) {
            products.add(Arrays.asList(
                    "Product " + i,
                    "Description for product " + i,
                    "$" + (10 + i),
                    i % 2 == 0 ? "true" : "false",  // In stock or not
                    "Category " + (i % 5),
                    "Color " + (i % 10),
                    "Brand " + (i % 3)
            ));
        }
    }

    @Override
    public void executeIteration(int iteration) {
        renderedResults.clear();
        String soyTemplate =
                "{namespace benchmark}\n" +
                        "{template main}\n" +
                        "  {@param user: list<string>}\n" + // user is a list of strings
                        "  {@param products: list<list<string>>}\n" + // products is a list of lists of strings
                        "  <h1>Hello, {$user[0]}!</h1>\n" +
                        "  <p>Your role is: {$user[1]}</p>\n" +
                        "  <ul>\n" +
                        "  {for $product in $products}\n" +
                        "    {if $product[2] == '$100'}\n" +
                        "      <li style=\"color:red;\">\n" +
                        "    {else}\n" +
                        "      <li>\n" +
                        "    {/if}\n" +
                        "      <b>{$product[0]}</b>: {$product[1]} - {$product[2]}\n" +
                        "      {if $product[3] == 'true'}\n" + // Check if product is in stock
                        "        <span>(In stock)</span>\n" +
                        "      {else}\n" +
                        "        <span>(Out of stock)</span>\n" +
                        "      {/if}\n" +
                        "      <ul>\n" +
                        "      {for $i in range(1, 5)}\n" + // list sub-products
                        "        <li>Subproduct {$i}</li>\n" +
                        "      {/for}\n" +
                        "      </ul>\n" +
                        "    </li>\n" +
                        "  {/for}\n" +
                        "  </ul>\n" +
                        "{/template}";

        // Compile the Soy file
        SoyFileSet sfs = SoyFileSet.builder()
                .add(soyTemplate, "benchmark.soy")
                .build();

        SoyTofu tofu = sfs.compileToTofu();
        renderer = tofu.newRenderer("benchmark.main");

        // Static simple input for user and products
        List<String> user = Arrays.asList("BenchmarkUser", "admin");

        // Create SoyListData for user
        SoyListData userData = new SoyListData(user);

        // Create SoyListData for products
        List<SoyListData> productsData = new ArrayList<>();
        for (List<String> product : products) {
            productsData.add(new SoyListData(product));
        }

        // Create SoyMapData containing user and products
        data = new SoyMapData("user", userData, "products", new SoyListData(productsData));

        // Render the output
        String output = renderer.setData(data).render();
        renderedResults.add(output);
    }


    @Override
    public void writeResult() {
        try {
            Files.write(Paths.get("output_" + getName() + ".html"), renderedResults);
        } catch (IOException e) {
            e.printStackTrace();
        }

    }

    @Override
    public boolean cleanupAndVerify() {
        try {
            // Read the content of the output file and ensure it's the same
            String fileContent = Files.readString(Paths.get("output_" + getName() + ".html"));
            Files.write(Paths.get("tmp_output_" + getName() + ".html"), renderedResults);
            String renderedResultsString = Files.readString(Paths.get("tmp_output_" + getName() + ".html"));
            return fileContent.equals(renderedResultsString);
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public String getName() {
        return "closureTemplatesBenchmark";
    }
}

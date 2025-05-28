package org.example;

import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.api.errors.GitAPIException;
import org.eclipse.jgit.lib.Ref;
import org.eclipse.jgit.lib.Repository;
import org.eclipse.jgit.storage.file.FileRepositoryBuilder;
import org.eclipse.jgit.util.FileUtils;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

// A simple program that uses JGit (java git) to continuously commits
// new files on new branches
public class JGitBenchmark implements BenchmarkTask{

    private final String repoPath = "JGitRepo";
    private final int iterations;

    private Repository repository;
    public JGitBenchmark(int iterations){
        this.iterations = iterations;
    }

    private void deleteRepo(File repoDir){
        if (repoDir.exists() && repoDir.isDirectory()) {
            try {
                FileUtils.delete(repoDir,1);
            }catch (IOException e){
                throw new RuntimeException(e);
            }
        }
    }
    @Override
    public void setup() {
        File repoDir = new File(repoPath);

        // 1 Delete the existing repository if it exists
        deleteRepo(repoDir);

        // 2 Create the repository folder
        try{
            Files.createDirectories(repoDir.toPath());
        } catch (IOException e) {
            throw new RuntimeException(e);
        }

        // 3 Initialize the Git repository in the folder
        try (Git git = Git.init().setDirectory(repoDir).call()) {
            // Add an initial commit to allow for branching
            File initialFile = new File(repoPath, "README.md");
            Files.write(Paths.get(initialFile.toURI()), "Initial commit\n".getBytes());
            git.add().addFilepattern("README.md").call();
            git.commit().setMessage("Initial commit").call();
            FileRepositoryBuilder builder = new FileRepositoryBuilder();
            repository = builder.setGitDir(new File(repoPath + "/.git"))
                    .readEnvironment()
                    .findGitDir()
                    .build();
            System.out.println("Git repository initialized at: " + repoPath);
        }catch (GitAPIException | IOException e){
            throw new RuntimeException(e);
        }
    }

    @Override
    public void executeIteration(int iteration) {
        File newFile = new File(repository.getDirectory().getParent(), iteration + ".txt");
        String fileName = newFile.getName();
        // Create and switch to a new branch for this file
        String branchName = "branch-for-" + fileName;
        try (Git git = new Git(repository)) {

            // Switch to 'main' before creating a new branch
            git.checkout().setName("master").call();

            // Create and switch to new branch for file
            git.checkout().setCreateBranch(true).setName(branchName).call();

            // Write content to the new file
            Files.write(newFile.toPath(), ("Commit for file " + fileName).getBytes());

            // Stage and commit the file
            git.add().addFilepattern(fileName).call();
            git.commit().setMessage("Added new file: " + fileName).call();
        }catch (Exception e){
            throw new RuntimeException(e);
        }
    }

    private List<String[]> getRepoStructure(){
        List<String[]> branchFiles = new ArrayList<>();
        try(Git git = new Git(repository)){
            // Iterate through all branches
            for (Ref branch : git.branchList().call()) {
                String branchName = branch.getName().replace("refs/heads/", "");

                // Checkout the branch to list its files
                git.checkout().setName(branchName).call();

                // List files in the working directory
                File repoDir = new File(repoPath);
                File[] files = repoDir.listFiles();

                if (files != null) {
                    for (File file : files) {
                        if (file.isFile() && !file.getName().endsWith(".tmp") && !file.getName().endsWith(".md")) {
                            branchFiles.add(new String[]{file.getName(), branchName});
                        }
                    }
                }
            }
        }catch (GitAPIException e){
            throw new RuntimeException(e);
        }

        // Sort rows by file numbers
        branchFiles.sort(Comparator.comparing(arr -> Integer.parseInt(arr[0].split("\\.")[0])));
        return branchFiles;
    }
    @Override
    public void writeResult() {
        File resultFile = new File("output_" + getName() + ".txt");

        try (BufferedWriter writer = new BufferedWriter(new FileWriter(resultFile))) {
            // Get repository structure
            List<String[]> branchFiles = getRepoStructure();
            // Write structure to file
            for (String[] entry : branchFiles) {
                writer.write(entry[0] + ";" + entry[1] + "\n");
            }

            System.out.println("Branch structure written to: " + resultFile.getAbsolutePath());

        } catch (Exception e) {
            throw new RuntimeException("Error writing branch structure to file", e);
        }
    }

    @Override
    public boolean cleanupAndVerify() {
        List<String[]> branchFiles = getRepoStructure();
        BufferedReader reader;
        int index = 0;
        try {
            reader = new BufferedReader(new FileReader("output_"+getName()+".txt"));
            String line = reader.readLine();

            while (line != null) {
                String[] components = line.split(";");
                if (!components[0].equals(branchFiles.get(index)[0]) || !components[1].equals(branchFiles.get(index)[1])){
                    return false;
                }

                // read next line
                line = reader.readLine();
                index++;
            }

            reader.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
        if (index == branchFiles.size()){
            return true;
        }else{
            return false;
        }

    }

    @Override
    public String getName() {
        return "JGitBenchmark";
    }
}

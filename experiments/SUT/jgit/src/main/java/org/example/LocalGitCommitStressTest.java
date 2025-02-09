package org.example;

import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.api.errors.GitAPIException;
import org.eclipse.jgit.lib.Repository;
import org.eclipse.jgit.storage.file.FileRepositoryBuilder;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

// A simple program that uses JGit (java git) to continuously commits
// new files on new branches and merges them back into main.
public class LocalGitCommitStressTest {

    public static void main(String[] args) throws InterruptedException, IOException, GitAPIException {
        String repositoryPath = "local-repo"; // Local repository path
        int numOfIterations = 1;
        for (int j = 0; j < numOfIterations; j++){
            // ✅ Reset the repository before running the stress test
            resetRepository(repositoryPath);

            int numOfCommits = 1000; // Number of iterations for testing
            for (int i = 0; i < numOfCommits; i++) {
                int commit = i;
                try {
                    runGitCommitOperations(repositoryPath, commit);
                } catch (IOException | GitAPIException e) {
                    System.err.println("Error during operation in iteration " + commit);
                    e.printStackTrace();
                }
            }
        }
        // Clean up local-repo
        File repoDir = new File(repositoryPath);
        if (repoDir.exists()) {
            deleteDirectory(repoDir);
        }
    }

    // 🔥 Fully reset the local Git repository
    private static void resetRepository(String repoPath) throws IOException, GitAPIException {
        File repoDir = new File(repoPath);

        // 1 Delete the existing repository if it exists
        if (repoDir.exists()) {
            deleteDirectory(repoDir);
        }

        // 2 Recreate the directory
        Files.createDirectories(repoDir.toPath());

        // 3 Reinitialize the Git repository
        try (Git git = Git.init().setDirectory(repoDir).call()) {
            System.out.println("✅ Fresh Git repository initialized at: " + repoPath);
            File initialFile = new File(repoPath, "README.md");
            Files.write(Paths.get(initialFile.toURI()), "Initial commit\n".getBytes());
            git.add().addFilepattern("README.md").call();
            git.commit().setMessage("Initial commit").call();
            System.out.println("✅ Initial commit created.");
        }
    }

    // Recursively delete a directory
    private static void deleteDirectory(File dir) throws IOException {
        if (dir.isDirectory()) {
            for (File file : dir.listFiles()) {
                deleteDirectory(file);
            }
        }
        Files.delete(dir.toPath());
    }

    // Simulate a series of Git operations
    public synchronized static void runGitCommitOperations(String repoPath, int iteration) throws IOException, GitAPIException {
        Repository repository = openRepository(repoPath);
        File newFile = new File(repository.getDirectory().getParent(), "file" + iteration + ".txt");
        createNewFileAndCommit(newFile, repository);
    }

    // Open an existing Git repository
    public static Repository openRepository(String repoPath) throws IOException {
        FileRepositoryBuilder builder = new FileRepositoryBuilder();
        return builder.setGitDir(new File(repoPath + "/.git"))
                .readEnvironment()
                .findGitDir()
                .build();
    }

    // Create a new file and commit it to a new branch, then merge it into main and delete the branch.
    public static synchronized void createNewFileAndCommit(File newFile, Repository repository) throws IOException, GitAPIException {
        try (Git git = new Git(repository)) {
            // Ensure 'main' branch exists; if not, create an initial commit
            if (repository.resolve("refs/heads/main") == null) {
                System.out.println("⚠️ 'main' branch not found. Creating it...");
                Files.write(Paths.get(repository.getDirectory().getParent(), "init.txt"), "Initial commit".getBytes());
                git.add().addFilepattern("init.txt").call();
                git.commit().setMessage("Initial commit").call();
                git.branchRename().setNewName("main").call();
            }

            // Switch to 'main' before creating a new branch
            git.checkout().setName("main").call();
            String fileName = newFile.getName();
            // Create and switch to a new branch for this file
            String branchName = "branch-for-" + fileName;
            git.checkout().setCreateBranch(true).setName(branchName).call();

            // Write content to the new file
            Files.write(newFile.toPath(), ("Commit for file " + fileName).getBytes());

            // Stage and commit the file
            git.add().addFilepattern(fileName).call();
            git.commit().setMessage("Added new file: " + fileName).call();

            // Switch back to 'main' after committing
            git.checkout().setName("main").call();

            // Merge the branch back into main and delete the branch
            mergeBranchIntoMain(branchName, repository);

            git.rm().addFilepattern(fileName).call();
            git.commit().setMessage("Removed file: " + fileName + " after merging").call();
        }
    }
    // Merges a branch into main and deletes it
    public static synchronized void mergeBranchIntoMain(String branchName, Repository repository) throws GitAPIException, IOException {
        try (Git git = new Git(repository)) {
            // Ensure we're on the main branch
            git.checkout().setName("main").call();

            // Merge the specified branch into main
            git.merge()
                    .include(repository.findRef(branchName))
                    .setMessage("Merged " + branchName + " into main")
                    .call();

            // Delete the merged branch
            git.branchDelete().setBranchNames(branchName).setForce(true).call();
        }
    }

}

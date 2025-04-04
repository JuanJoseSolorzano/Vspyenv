#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>

#define MAX_PATH 1024
#define MAX_EXCLUDE 8

const char *EXCLUDE_FOLDERS[MAX_EXCLUDE] = {"out", "bin", "report", "results", "logs", "build", "__pycache__", "node_modules"};

// Check if a folder is excluded
int is_excluded(const char *path) {
    for (int i = 0; i < MAX_EXCLUDE; i++) {
        if (strstr(path, EXCLUDE_FOLDERS[i]) != NULL) {
            return 1;
        }
    }
    return 0;
}

// Check if a directory contains Python files
int has_python_files(const char *path) {
    struct dirent *entry;
    DIR *dir = opendir(path);
    if (!dir) return 0;

    while ((entry = readdir(dir)) != NULL) {
        if (strstr(entry->d_name, ".py") != NULL) {
            closedir(dir);
            return 1;
        }
    }
    closedir(dir);
    return 0;
}

// Recursively scan directories and add valid paths to the workspace file
void scan_directory(const char *base_path, FILE *workspace_file) {
    struct dirent *entry;
    DIR *dir = opendir(base_path);
    if (!dir) return;

    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) continue;

        char path[MAX_PATH];
        snprintf(path, sizeof(path), "%s/%s", base_path, entry->d_name);

        struct stat path_stat;
        stat(path, &path_stat);

        if (S_ISDIR(path_stat.st_mode) && !is_excluded(path)) {
            if (has_python_files(path)) {
                fprintf(workspace_file, "       \"%s\",\n", path);
            }
            scan_directory(path, workspace_file);
        }
    }
    closedir(dir);
}

// Create a Visual Studio Code workspace file
void create_workspace_file(const char *target_path) {
    char workspace_file_path[MAX_PATH];
    snprintf(workspace_file_path, sizeof(workspace_file_path), "%s.code-workspace", target_path);

    FILE *workspace_file = fopen(workspace_file_path, "w");
    if (!workspace_file) {
        perror("Error creating workspace file");
        return;
    }

    fprintf(workspace_file, "{\n");
    fprintf(workspace_file, "    \"folders\": [\n");
    fprintf(workspace_file, "        {\"path\": \".\"},\n");

    scan_directory(target_path, workspace_file);

    fprintf(workspace_file, "    ],\n");
    fprintf(workspace_file, "    \"settings\": {\n");
    fprintf(workspace_file, "        \"python.analysis.extraPaths\": []\n");
    fprintf(workspace_file, "    }\n");
    fprintf(workspace_file, "}\n");

    fclose(workspace_file);
    printf("[+] Workspace file created: %s\n", workspace_file_path);
}

// Create a .env file for Python path configuration
void create_env_file(const char *target_path) {
    char env_file_path[MAX_PATH];
    snprintf(env_file_path, sizeof(env_file_path), "%s/.env", target_path);

    FILE *env_file = fopen(env_file_path, "w");
    if (!env_file) {
        perror("Error creating .env file");
        return;
    }

    fprintf(env_file, "PYTHONPATH=\"%s\"\n", target_path);
    fclose(env_file);
    printf("[+] .env file created: %s\n", env_file_path);
}

// Main function
int main(int argc, char *argv[]) {
    char target_path[MAX_PATH];
    if (argc > 1) {
        strncpy(target_path, argv[1], MAX_PATH);
    } else {
        if (!getcwd(target_path, sizeof(target_path))) {
            perror("Error getting current directory");
            return 1;
        }
    }

    printf("Target path: %s\n", target_path);

    create_workspace_file(target_path);
    create_env_file(target_path);
    system("pause");    
    return 0;
}

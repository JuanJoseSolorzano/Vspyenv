# 🚀 Visual Studio Code Python Suite Environment Setup

## 🌟 Overview

The `vscode-pysuite.ps1` script automates the creation of a Visual Studio Code workspace file for Python projects. It scans the directory structure, identifies Python files, and configures the workspace with appropriate folder paths and debugging settings. Additionally, it generates a `.env` file for managing the `PYTHONPATH` environment variable and creates a `pyenv.py` utility script for managing Python paths programmatically.

## ✨ Features

- 🗂️ Automatically generates a `.code-workspace` file for Visual Studio Code.
- 🚫 Excludes specific folders (e.g., `out`, `bin`, `report`, `__pycache__`) from the workspace.
- 🐍 Configures debugging settings for Python development.
- 📄 Creates a `.env` file to set the `PYTHONPATH` environment variable.
- 🛠️ Generates a `pyenv.py` script for managing Python paths and executing scripts.
- 🖥️ Opens the workspace in Visual Studio Code if installed.

## 📋 Prerequisites

- 💻 Windows PowerShell
- 🖊️ Visual Studio Code (optional, for opening the workspace file)
- 🐍 Python 3.9 or higher

## ▶️ Usage

### 🏃 Running the Script

1. Open a PowerShell terminal.
2. Navigate to the directory containing the `vscode-pysuite.ps1` script.
3. Execute the script using the following command:

   ```powershell
   .\vscode-pysuite.ps1 -target_path "C:\Path\To\Your\Project"
   ```

   If no `-target_path` is provided, the script will use the current directory by default.

### 💡 Example Commands

- Run the script for the current directory:
  ```powershell
  .\vscode-pysuite.ps1
  ```

- Run the script for a specific directory:
  ```powershell
  .\vscode-pysuite.ps1 -target_path "C:\Projects\MyPythonApp"
  ```

## 📦 Output

1. **📁 Workspace File**: A `.code-workspace` file is created in the target directory.
2. **📄 Environment File**: A `.env` file is generated with the `PYTHONPATH` variable.
3. **🛠️ Python Utility Script**: A `pyenv.py` script is created in the Python root directory.

## 🔧 Script Functions

### 🗂️ `vscenv`

- Scans the target directory for Python files.
- Creates a `.code-workspace` file with folder paths and debugging settings.
- Excludes specific folders from the workspace.

### 📁 `CreateVSfile`

- Generates the `.code-workspace` file.
- Adds folder paths containing Python files to the workspace.

### 📄 `CreateEnvFile`

- Creates a `.env` file with the `PYTHONPATH` variable.

### 🛠️ `pyenvfile`

- Generates a `pyenv.py` script for managing Python paths and executing scripts.

### 🖼️ `autoTitle`

- Displays a title banner with licensing information when the script is executed.

## 📜 License

This project is licensed under the MIT License. See the license information in the script for details.

## 👨‍💻 Author

- **Juan Jose Solorzano**
- 📅 Date: October 3, 2023
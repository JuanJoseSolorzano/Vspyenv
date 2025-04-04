<#
  .SYNOPSIS
  Automates the creation of a Visual Studio Code workspace file for a given directory.

  .DESCRIPTION
  This script scans the directory structure of a specified path, identifies Python files, 
  and generates a Visual Studio Code workspace file. The workspace file includes folder paths 
  and debugging settings tailored for Python development. Specific folders such as 'out', 
  'bin', 'report', and others are excluded from the workspace. If Visual Studio Code is installed, 
  the script automatically opens the generated workspace file.

  .PARAMETER target_path
  The root directory path for which the workspace file will be created. If no path is provided, 
  the current directory is used by default.

  .EXAMPLE
  # Run the script for the current directory:
  .\vs-suite.ps1

  # Run the script for a specific directory:
  .\vs-suite.ps1 -target_path "C:\Projects\MyPythonApp"

  .NOTES
  Author: Juan Jose Solorzano
  Date: 2023-10-03
  Version: 1.0
  Dependencies: Visual Studio Code (optional, for opening the workspace file)
  License: MIT License
#>
$EXCLUDE_FOLDERS = @('out', 'bin', 'report', 'results', 'logs', 'build', '__pycache__')
function vscenv {
    param($target_path)
    # Global variables used to the file code structure
    $start_content = '// Author: Juan Jose Solorzano
// Date: 2023-10-03 
// Copyright (c) 2023 Juan Jose Solorzano.
// MIT License
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// -------------------------------------------------------------------------------------------------------
// Description: 
// This script automates the creation of a Visual Studio Code workspace file for a given directory. 
// It scans the directory structure, identifies Python files, and configures the workspace with appropriate 
// folder paths and debugging settings. The script also excludes specific folders from the workspace and 
// ensures the workspace file is opened in Visual Studio Code if installed.
{
    "folders": [{"path": "."}],
    "settings": {"python.analysis.extraPaths": ['

    $debug_content = '    "launch": {
        "version": "0.2.0",
        "configurations": [{
            "name": "Python: DebugForTA",
            "type": "debugpy",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal",
            "justMyCode": false,
        }],
    }
}'
    
    function CreateVSfile($suite_path) {
        # Create the .workspace file
        # Get the path info like: Name | Folder | Foldername 
        $path_info =Get-ChildItem $suite_path -Recurse | Select-Object Name, `
        @{ n = 'Folder'; e = { Convert-Path $_.PSParentPath } }, `
        @{ n = 'Foldername'; e = { ($_.PSPath -split '[\\]')[-2] } }
        $suite_root_path = $path_info.Folder[0] # Get the root directory
        $suite_name = Split-Path -Leaf $suite_path
        $suite_paths = $path_info.Folder # Returns all directories path
        $work_space_name = "$suite_name.code-workspace"
        $suite_paths = $suite_paths | Select-Object -Unique # Remove duplicates
        $root_dir = $suite_paths[0] # Get the root directory
        $file_exists = [System.IO.File]::Exists("$suite_path\\$work_space_name") # Check if the file exists
        if($file_exists) {
            Write-Host "[!] - File $work_space_name already exists. Removing it... "
            Remove-Item -Force "$suite_path\\$work_space_name"
        }else{
            Write-Host "[+] - Creating file '$work_space_name' ... "
            New-Item $work_space_name -ItemType "file" >> $null # Create the file
        }
        Add-Content $work_space_name $start_content # add the 
        Write-Host "[*] - Adding folders to the workspace file... Wait a moment while creating."
        foreach ($path in $suite_paths) {
            $exclude_match = $EXCLUDE_FOLDERS | ForEach-Object { $path -like "*\$_\*" }
            if (-not ($exclude_match -contains $true)) {
                $test = Get-ChildItem $path
                if ($test.Name.EndsWith(".py") -eq "True") {
                    $workspacepath = $path.Replace($root_dir, '${workspaceFolder}')
                    $modules_path = '       "' + $workspacepath.Replace('\', '/') + '"' + ','
                    if ($modules_path -ne " " -or $null -ne $modules_path) {
                        Add-Content $work_space_name $modules_path
                        $pypath = $modules_path.Replace(',', ';')
                        $pypath = $pypath.Replace('"', '')
                        $pypath = $pypath.Replace('${workspaceFolder}',$suite_root_path)
                        $arr += @($pypath)
                    }
                }
            }
        }

        $python_path = echo "$arr".Replace(' ', '')
        #$exec_modules_temp = $exec_modules_temp.Insert(0, '"')
        $end_content = '    ],
    "python.terminal.activateEnvInCurrentTerminal": true,
    "python.terminal.launchArgs": [
        "-m",
        "pyenv"
    ]},'
        Add-Content $work_space_name $end_content
        Add-Content $work_space_name $debug_content
        try {
            & code "$work_space_name" # Open the workspace in Visual Studio Code
        } catch {
            Write-Host "[!] No Visual Code app installed."
            Remove-Item "$work_space_name" -Force # Remove the workspace file if VS Code is not installed
        }
        return $python_path
    }
    function CreateEnvFile {
        param($paths)
        # Create the .env file
        $env_file = ".env"
        if (Test-Path $env_file) {
            Write-Host "[!] - File $env_file already exists. Removing it... "
            Remove-Item -Force $env_file
        } else {
            Write-Host "[+] - Creating file '$env_file' ... "
            New-Item $env_file -ItemType "file" >> $null
        }
        Add-Content $env_file "PYTHONPATH=`"$paths`""
    }
    # Internal Main Flow Code
    if (($null -eq $target_path) -or ('.' -eq $target_path)) {
        $python_path = CreateVSfile -suite_path '.'
        #[System.Environment]::SetEnvironmentVariable("PYTHONPATH", "`"$python_path`"", 'User')
        CreateEnvFile -paths $python_path
    } else {
        if (Test-Path $target_path) {
            $python_path = CreateVSfile -suite_path $target_path
            #[System.Environment]::SetEnvironmentVariable("PYTHONPATH", $python_path, 'User')
            CreateEnvFile -paths $python_path
        } else {
            Write-Host "[!] Error: Path not found !!!"
        }
    }
}

function pyenvfile {
    $file_content = '# -*- coding: UTF-8 -*-
# ************************************************************************************************************#
# License:    MIT                                                                                             #
#                                                                                                             #
# Permission is hereby granted, free of charge, to any person obtaining a copy                                #
# of this software and associated documentation files (the "Software"), to deal                               #
# in the Software without restriction, including without limitation the rights                                #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell                                   #
# copies of the Software, and to permit persons to whom the Software is                                       #
# furnished to do so, subject to the following conditions:                                                    #
#                                                                                                             #
# The above copyright notice and this permission notice shall be included in all                              #
# copies or substantial portions of the Software.                                                             #
#                                                                                                             #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR                                  #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,                                    #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE                                 #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER                                      #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,                               #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE                               #
# SOFTWARE.                                                                                                   #
# Copyright (c) 2023 Juan Jose Solorzano.                                                                     #
# ************************************************************************************************************#
# Tool chain: $Python:    >3.9                                                                                #
# Filename:   $WorkFile:  pyenv.py                                                                            #
# Depencies:  $WorkFile:  os, sys, fnmatch, runpy                                                             #
# Revision:   $Revision:  1.0                                                                                 #
# Author:     $Author:    Solorzano, Juan Jose                                                                #
# Date:       $Date:      18/03/24                                                                            #
# ************************************************************************************************************#
# Module information:                                                                                         #
# ------------------------------------------------------------------------------------------------------------#
# This module provides utilities for managing Python environment paths and executing scripts.                 #
#                                                                                                             #
# Functions:                                                                                                  #
# - getAllPaths(targetPath): Retrieves all paths containing Python files starting from the target path.       #
# - getSuiteRootPath(start_dir): Identifies the root path of the suite by searching for a .code-workspace     #
#   file.                                                                                                     # 
# - setSysPath(pathList): Adds specified paths to the Python sys.path for module resolution.                  #
#                                                                                                             #
# Usage:                                                                                                      #
# Run this script with a target Python script as an argument to execute it within the configured environment. #
# Example: python pyenv.py <target_script>                                                                    #
# ************************************************************************************************************#

import sys
import os
import fnmatch #type: ignore
import runpy #type: ignore

def getAllPaths(targetPath):
    """
    Returns all paths starting from the mainPath as a list of strings
    Returns [] if mainPath was not found
    Returns [mainPath] if mainPath has no sub-paths
    """
    pathList = []
    for path, _, files in os.walk(targetPath): 
        # add only folders that contains a .py source file
        for fileName in files:
            if fnmatch.fnmatch(fileName, "*.py"):
                if path.__contains__("__pycache__"):
                    continue
                pathList.append(path)
                break
    return pathList

def getSuiteRootPath(start_dir=os.getcwd()):
    """
    Returns the root path of the suite
    """
    current_dir = start_dir
    levels = 50  # Number of levels to go up
    root_path = None
    for _ in range(levels):
        current_dir = os.path.dirname(current_dir)
        for file in os.listdir(current_dir):
            if fnmatch.fnmatch(file, "*.code-workspace"):
                print(current_dir)
                root_path = current_dir
                break
    return root_path 

def setSysPath(pathList):
    """
    Adds the paths in pathList to sys.path
    """
    for path in pathList:
        if path not in sys.path:
            sys.path.append(path)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python pyenv.py <target_script>")
        sys.exit(1)
    target = sys.argv[1]
    if not os.path.isfile(target):
        print("Error: The file %s does not exist."%target)
        sys.exit(1)
    setSysPath((getAllPaths(getSuiteRootPath())))
    # Execute the external script using runpy for better safety and efficiency
    try:
        runpy.run_path(target, run_name="__main__")
    except Exception as e:
        print(f"Error while executing the script: {e}")'
        
    # Create the pyenv.py file
    $python_root_path = "C:\LegacyApp\Python39"
    $file_name = "$python_root_path\pyenv.py"
    if (Test-Path $file_name) {
        Write-Host "[!] - File $file_name already exists. Removing it... "
        Remove-Item -Force $file_name
    } else {
        Write-Host "[+] - Creating file '$file_name' ... "
    }
    New-Item $file_name -ItemType "file" >> $null
    Add-Content $file_name $file_content
    Write-Host "[+] - Creating file '$file_name' ... "
}



# Main flow for .ps1 file.
function autoTitle {
    Write-Output "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    Write-Output "                            RUNNING PYTHON ENVIRONMENT"
    Write-Output "                                     FOR VSCODE"
    Write-Output "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    Write-Output "MIT License:"
    Write-Output "Copyright (c) $(Get-Date -Format yyyy) Juan Jose Solorzano"
    Write-Output "The above copyright notice and this permission notice shall be included in all"
    Write-Output "copies or substantial portions of the Software."
    Write-Output "-------------------------------------------------------------------------------------"
    Write-Output "> Press Ctrl + C to cancel the script execution."
    Write-Output "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

}

# Call the function when executing the script.
try {
    autoTitle
    vscenv (Get-Location).Path
    pyenvfile
} catch {
    Write-Host "An error occurred: $($_.Exception.Message)"
}
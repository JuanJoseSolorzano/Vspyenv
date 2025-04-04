  <#
  .SYNOPSIS
  Provides a description of the script or function.

  .DESCRIPTION
  Gives a detailed explanation of what the script or function does, including its purpose and functionality.

  .PARAMETER <ParameterName>
  Describes a specific parameter, its purpose, and any expected input.

  .EXAMPLE
  Provides an example of how to use the script or function.

  .NOTES
  Includes any additional information, such as author, version, or date.
  #>

function vscenv {
  param($target_path)
  # Global variables used to the file code structure
  $cont = '{
      "folders": [
        {
          "path": "."
        }
      ],
      "settings": {"python.analysis.extraPaths": ['
  
  $debug = '"launch": {
            "version": "0.2.0",
            "configurations": [{
            "name": "Python: DebugForTA",
            "type": "debugpy",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal" },
          ]}
        }'

  function CreateVSfile($suite_path) {
      $path_info =Get-ChildItem $suite_path -Recurse | Select Name, `
      @{ n = 'Folder'; e = { Convert-Path $_.PSParentPath } }, `
      @{ n = 'Foldername'; e = { ($_.PSPath -split '[\\]')[-2] } }
      $dir = Get-ChildItem $suite_path
      $name = $dir.Directory.Name[0]
      $suite_paths = $path_info.Folder
      $workSpaceName = "$name.code-workspace"
      $suite_paths = $suite_paths | Select-Object -Unique
      $root_dir = $suite_paths[0]
      $exists = [System.IO.File]::Exists($workSpaceName)
      if($exists){
        Remove-Item -Force $workSpaceName
      }else{
        New-Item $workSpaceName -ItemType "file" >> $null
      }
      Add-Content $workSpaceName $cont
      foreach($path in $suite_paths){
        if(-not $path.contains('\out\ta\report\')){
          $test = $(ls $path)
          if($test.Name.EndsWith(".py") -eq "True"){
            $workspacepath = $path.Replace($root_dir,'${workspaceFolder}')
            $modules_path='                 "' + $workspacepath.Replace('\','/') + '"' + ','
            if($modules_path -ne " " -or $null -ne $modules_path)
            {
              Add-Content $workSpaceName $modules_path
              $pypaht = $modules_path.Replace(',',';')
              $pypaht = $pypaht.Replace('"','')
              $arr += @($pypaht) 
            }
          }
        }
      }
      $exec_modules_temp = echo "$arr".Replace(' ','')
      $exec_modules_temp = $exec_modules_temp.Insert(0,'"')
      $exec_modules = $exec_modules_temp.Insert(($exec_modules_temp.Length),'"')
      $end_paths = ']},'
      Add-Content $workSpaceName $end_paths
      Add-Content $workSpaceName $debug
      try {
        & code "$name.code-workspace"
      }
      catch {
        echo "[!] No Visual Code app installed."
		    rm "$name.code-workspace"
		    #rm .env
      }
  }
  # Internal Main Flow Code
  if(($null -eq $target_path) -or ('.' -eq $target_path)){
    CreateVSfile('.')
  }
  else 
  {
    if(Test-Path $target_path){
      CreateVSfile($target_path)
    }
    else {
      echo "[!] Error: Path not found !!!"
    }
  }
}

# Main flow for .ps1 file.
vscenv $curr_dir
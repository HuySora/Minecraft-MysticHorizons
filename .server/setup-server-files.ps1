param (
   [switch]$Silent = $false
)

# Check if the script is running with elevated privileges
if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    # Get the absolute path of the script
    $absolutePath = Resolve-Path $MyInvocation.MyCommand.Path

    # Prepare the arguments to pass, including the script path
    $args = @("-File `"$absolutePath`"")

    # Add bound parameters to the argument list
    if ($Silent) {
        $args += "-Silent"
    }

    # Start a new PowerShell process with elevated privileges and pass the arguments
    Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList $args
    Exit
}
# Push location to the current script directory
Push-Location $PSScriptRoot

# Source directory and target link directory for each folder
$folders = @{
    "config" = @{
        "source" = "..\config"
        "ignoreNames" = @() # Add file or folder names to ignore
    }
    "defaultconfigs" = @{
        "source" = "..\defaultconfigs"
        "ignoreNames" = @()
    }
    "libraries" = @{
        "source" = "..\..\libraries"
        "target" = "libraries"
        "ignoreNames" = @()
        "link" = $true
    }
    "mods" = @{
        "source" = "..\mods"
        "ignoreNames" = @(
            "AmbientSounds_FORGE_v6.1.4_mc1.20.1.jar",
            "BadOptimizations-2.2.1-1.20.1.jar",
            "BetterF3-7.0.2-Forge-1.20.1.jar",
            "BetterModsButton-v8.0.2-1.20.1-Forge.jar",
            "BHMenu-Forge-1.20.1-2.4.2.jar",
            "blur-forge-3.1.1.jar",
            "chunksfadein-1.0.7-1.20.1.jar",
            "chat_heads-0.13.7-forge-1.20.jar",
            "cherishedworlds-forge-6.1.7+1.20.1.jar",
            "Controlling-forge-1.20.1-12.0.2.jar",
            "CullLessLeaves-Reforged-1.20.1-1.0.5.jar",
            "defaultoptions-forge-1.20-18.0.1.jar",
            "drippyloadingscreen_forge_3.0.9_MC_1.20.1.jar",
            "embeddium-0.3.31+mc1.20.1.jar",
            "EnchantmentDescriptions-Forge-1.20.1-17.1.19.jar",
            "EnhancedVisuals_FORGE_v1.8.1_mc1.20.1.jar",
            "entity_model_features_forge_1.20.1-2.4.1.jar",
            "entity_texture_features_forge_1.20.1-6.2.9.jar",
            "entityculling-forge-1.7.2-mc1.20.1.jar",
            "FancyBlockParticles-1.20.1-forge-20.1.2.0.jar",
            "fancymenu_forge_3.3.2_MC_1.20.1.jar",
            "farsight-1.20.1-3.7.jar",
            "ImmediatelyFast-Forge-1.3.3+1.20.4.jar",
            "ItemBorders-1.20.1-forge-1.2.2.jar",
            "ItemPhysicLite_FORGE_v1.6.5_mc1.20.1.jar",
            "inventoryhud.forge.1.20.1-3.4.26.jar",
            "leawind_third_person-v2.2.0-mc1.20-1.20.1-forge.jar",
            "LegendaryTooltips-1.20.1-forge-1.4.5.jar",
            "loot_journal-forge-1.20.1-4.0.2.jar",
            "lootbeams-1.20.1-1.2.6.jar",
            "MouseTweaks-forge-mc1.20.1-2.25.1.jar",
            "notenoughanimations-forge-1.9.0-mc1.20.1.jar",
            "oculus-flywheel-compat-forge1.20.1+1.1.4.jar",
            "oculus-mc1.20.1-1.8.0.jar",
            "OverflowingBars-v8.0.1-1.20.1-Forge.jar",
            "PresenceFootsteps-1.20.1-1.9.1-beta.1.jar",
            "reactivemusic-0.4.0+1.20.1.jar",
            "sodiumextras-forge-1.0.6-1.20.1.jar",
            "ToastControl-1.20.1-8.0.3.jar",
            "TravelersTitles-1.20-Forge-4.0.2.jar",
            "YeetusExperimentus-Forge-2.3.1-build.6+mc1.20.1.jar",
            "XaeroPlus-2.24.9+forge-1.20.1-WM1.39.2-MM24.6.1.jar",
            "zume-1.1.4.jar"
        )
    }
    "scripts" = @{
        "source" = "..\scripts"
        "ignoreNames" = @()
    }
}

# Function to copy files from source to target directory
function Copy-Files {
    param(
        [string]$sourceDirectory,
        [string]$targetDirectory,
        [string[]]$ignoreNames
    )

    # Get files and folders in the source directory
    $items = Get-ChildItem -Path $sourceDirectory

    # Loop through each item and copy it to the target directory
    foreach ($item in $items) {
        # Check if item is not in the ignore list
        if ($ignoreNames -notcontains $item.Name) {
            # Check if item is a directory or file
            if ($item.PSIsContainer) {
                # Copy directory to target directory
                Write-Host "Copying directory: Copy-Item -Path `"$($item.FullName)`" -Destination `"$targetDirectory\$($item.Name)`" -Recurse -Force"
                $src = [Management.Automation.WildcardPattern]::Escape($item.FullName)
                $dest = [Management.Automation.WildcardPattern]::Escape("$targetDirectory\$($item.Name)")
                Copy-Item -Path $src -Destination $dest -Recurse -Force
            } else {
                # Copy file to target directory
                Write-Host "Copying file: Copy-Item -Path `"$($item.FullName)`" -Destination `"$targetDirectory`" -Force"
                $src = [Management.Automation.WildcardPattern]::Escape($item.FullName)
                $dest = [Management.Automation.WildcardPattern]::Escape($targetDirectory)
                Copy-Item -Path $src -Destination $dest -Force
            }
        }
    }
}

# Loop through each folder and create symbolic links or copy files
foreach ($folderName in $folders.Keys) {
    $folder = $folders[$folderName]
    $sourceDirectory = $folder["source"]
    $targetDirectory = $folderName
    $ignoreNames = $folder["ignoreNames"]

    # Remove previous symbolic link and folder if they exist
    if (Test-Path -Path $targetDirectory) {
        Write-Host "Removing previous symbolic link and folder: rmdir `"$targetDirectory`" /s /q"
        git rm --cached -r "$targetDirectory"
        # Check if item is a directory or file
        if (Test-Path -Path $targetDirectory -PathType Container) {
            cmd /c rmdir "$targetDirectory" /s /q
        } else {
            cmd /c del "$targetDirectory" /q
        }
    }

    # Check if symbolic link should be created
    if ($folder["link"]) {
        # Create symbolic link for directory
        Write-Host "Creating symbolic link for folder: mklink /D `"$targetDirectory`" `"$sourceDirectory`""
        cmd /c mklink /D "$targetDirectory" "$sourceDirectory"
        git reset HEAD -- "$targetDirectory"
    } else {
        # Create new target directory
        Write-Host "Creating target directory: New-Item -Path `"$targetDirectory`" -ItemType Directory"
        New-Item -Path $targetDirectory -ItemType Directory | Out-Null
        # Copy files from source to target directory
        Write-Host "Copying files to target directory..."
        Copy-Files -sourceDirectory $sourceDirectory -targetDirectory $targetDirectory -ignoreNames $ignoreNames
    }
}

# Pop back to the previous location
Pop-Location

# Conditionally pause based on -Silent argument
if (-not $Silent) {
    cmd /c pause
}
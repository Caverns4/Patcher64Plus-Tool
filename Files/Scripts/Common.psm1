function SetWiiVCMode([Boolean]$Enable) {
    
    if ( ($Enable -eq $IsWiiVC) -and $GameIsSelected) { return }

    $global:IsWiiVC = $Enable
    if ($IsWiiVC)   { $CustomTitleTextBox.MaxLength = $VCTitleLength  }
    else            { $CustomTitleTextBox.MaxLength = $GameConsole.rom_title_length }
    
    EnablePatchButtons (IsSet $GamePath)
    GetHeader
    SetModeLabel
    ChangePatchPanel

}



#==================================================================================================================================================================================================================================================================
function CreateToolTip($Form, $Info) {

    # Create ToolTip
    $ToolTip = New-Object System.Windows.Forms.ToolTip
    $ToolTip.AutoPopDelay = 32767
    $ToolTip.InitialDelay = 500
    $ToolTip.ReshowDelay = 0
    $ToolTip.ShowAlways = $True
    if ( (IsSet $Form) -and (IsSet $Info) ) { $ToolTip.SetToolTip($Form, $Info) }
    return $ToolTip

}



#==============================================================================================================================================================================================
function ChangeConsolesList() {
    
    # Reset
    $ConsoleComboBox.Items.Clear()

    $Items = @()
    Foreach ($Console in $Files.json.consoles.console) {
        $Items += $Console.title
    }

    $ConsoleComboBox.Items.AddRange($Items)

    # Reset last index
    For ($i=0; $i -lt $Items.Length; $i++) {
        if ($GameConsole.title -eq $Items[$i]) { $ConsoleComboBox.SelectedIndex = $i }
    }

    if ($Items.Length -gt 0 -and $ConsoleComboBox.SelectedIndex -eq -1) {
        try { $ConsoleComboBox.SelectedIndex = $Settings["Core"][$ConsoleComboBox.Name] }
        catch { $ConsoleComboBox.SelectedIndex = 0 }
    }

}



#==============================================================================================================================================================================================
function ChangeGamesList() {
    
    # Set console
    foreach ($Item in $Files.json.consoles.console) {
        if ($Item.title -eq $ConsoleComboBox.Text) { $global:GameConsole = $Item }
    }

    # Reset
    $CurrentGameComboBox.Items.Clear()
    if (!$IsWiiVC) { $CustomTitleTextBox.MaxLength = $GameConsole.rom_title_length }

    $Items = @()
    Foreach ($Game in $Files.json.games.game) {
        if ( ($ConsoleComboBox.text -eq $GameConsole.title) -and ($GameConsole.mode -contains $Game.console) ) {
            if ( ( $IsWiiVC -and $Game.support_vc -eq 1) -or (!$IsWiiVC) ) { $Items += $Game.title }
        }
        elseif ($Game.console -contains "All") { $Items += $Game.title }
    }

    $CurrentGameComboBox.Items.AddRange($Items)

    # Reset last index
    For ($i=0; $i -lt $Items.Length; $i++) {
        if ($GameType.title -eq $Items[$i]) { $CurrentGameComboBox.SelectedIndex = $i }
    }

    if ($Items.Length -gt 0 -and $CurrentGameComboBox.SelectedIndex -eq -1) {
        try { $CurrentGameComboBox.SelectedIndex = $Settings["Core"][$CurrentGameComboBox.Name] }
        catch { $CurrentGameComboBox.SelectedIndex = 0 }
    }

    SetVCPanel

}



#==============================================================================================================================================================================================
function ChangePatchPanel() {
    
    # Return is no GameType or game file is set
    if (!(IsSet $GameType)) { return }


    # Reset
    $Patches.Group.text = $GameType.mode + " - Patch Options"
    $Patches.ComboBox.Items.Clear()

    # Set combobox for patches
    $Items = @()
    foreach ($i in $Files.json.patches.patch) {
        if ( ($IsWiiVC -and $i.console -eq "Wii VC") -or (!$IsWiiVC -and $i.console -eq "Native") -or ($i.console -eq "Both") ) {
            $Items += $i.title
            if (!(IsSet $FirstItem)) { $FirstItem = $i }
        }
    }

    $Patches.ComboBox.Items.AddRange($Items)

    # Reset last index
    For ($i=0; $i -lt $Items.Length; $i++) {
        Foreach ($Item in $Files.json.patches.patch) {
            if ($Item.title -eq $GamePatch.title -and $Item.title -eq $Items[$i]) { $Patches.ComboBox.SelectedIndex = $i }
        }
    }

    if ($InputPaths.GameTextBox.Text -notlike '*:\*') { $global:IsActiveGameField = $True }
    if ($Items.Length -gt 0 -and $Patches.ComboBox.SelectedIndex -eq -1) {
        try { $Patches.ComboBox.SelectedIndex = $Settings["Core"][$Patches.ComboBox.Name] }
        catch { $Patches.ComboBox.SelectedIndex = 0 }
    }
    
}



#==============================================================================================================================================================================================
function SetMainScreenSize() {
    
    # Show / Hide Custom Header
    if ($IsWiiVC) {
        $CustomTitleTextBoxLabel.Text = "Channel Title:"
        $CustomHeaderGroup.Text = " Custom Channel Title and GameID "
    }
    else {
        $CustomTitleTextBoxLabel.Text = "Game Title:"
        $CustomHeaderGroup.Text = " Custom Game Title and GameID "
    }

    # Custom Header Panel Visibility
    $CustomHeaderPanel.Visible = ($GameConsole.rom_title -gt 0) -or ($GameConsole.rom_gameID -gt 0) -or $IsWiiVC
    $CustomTitleTextBox.Visible = $CustomTitleTextBoxLabel.Visible = ($GameConsole.rom_title -gt 0) -or $IsWiiVC
    $CustomGameIDTextBox.Visible = $CustomGameIDTextBoxLabel.Visible = ($GameConsole.rom_gameID -eq 1) -or $IsWiiVC
    $CustomRegionCodeLabel.Visible = $CustomRegionCodeComboBox.Visible = ($GameConsole.rom_gameID -eq 2)
    $InputPaths.InjectPanel.Visible = $IsWiiVC
    $VC.Panel.Visible = $IsWiiVC

    # Set Input Paths Sizes
    $InputPaths.GamePanel.Location = $InputPaths.InjectPanel.Location = $InputPaths.PatchPanel.Location = New-Object System.Drawing.Size(10, 50)
    if ($IsWiiVC) {
        $InputPaths.InjectPanel.Top = $InputPaths.GamePanel.Bottom + 15
        $InputPaths.PatchPanel.Top = $InputPaths.InjectPanel.Bottom + 15
    }
    else {
        $InputPaths.PatchPanel.Top = $InputPaths.GamePanel.Bottom + 15
    }

    # Positioning
    if (IsSet $GamePath)   { $CurrentGamePanel.Location = New-Object System.Drawing.Size(10, ($InputPaths.PatchPanel.Bottom + 5)) }
    else                   { $CurrentGamePanel.Location = New-Object System.Drawing.Size(10, ($InputPaths.GamePanel.Bottom + 5)) }
    $CustomHeaderPanel.Location = New-Object System.Drawing.Size(10, ($CurrentGamePanel.Bottom + 5))

    # Set VC Panel Size
    if ($GameConsole.options_vc -eq 0)                               { $VC.Panel.Height = $VC.Group.Height = 70 }
    elseif ($GameType.patches_vc -gt 2)                              { $VC.Panel.Height = $VC.Group.Height = 105 }
    elseif ($GameType.patches_vc -gt 0 -or $GameConsole.t64 -eq 1)   { $VC.Panel.Height = $VC.Group.Height = 90 }
    else                                                             { $VC.Panel.Height = $VC.Group.Height = 70 }

    # Arrange Panels
    if ($IsWiiVC) {
        if ($GameType.patches) {
            $Patches.Panel.Location = New-Object System.Drawing.Size(10, ($CustomHeaderPanel.Bottom + 5))
            $VC.Panel.Location = New-Object System.Drawing.Size(10, ($Patches.Panel.Bottom + 5))
        }
        else { $VC.Panel.Location = New-Object System.Drawing.Size(10, ($CustomHeaderPanel.Bottom + 5)) }
        $MiscPanel.Location = New-Object System.Drawing.Size(10, ($VC.Panel.Bottom + 5))
    }
    else {
        if ( ($GameConsole.rom_title -eq 0) -and ($GameConsole.rom_gameID -eq 0) ) {
            if ($GameType.patches) { $Patches.Panel.Location = New-Object System.Drawing.Size(10, ($CurrentGamePanel.Bottom + 5)) }
            else                   { $MiscPanel.Location = New-Object System.Drawing.Size(10, ($CurrentGamePanel.Bottom + 5)) }
        }
        else {
            if ($GameType.patches) { $Patches.Panel.Location = New-Object System.Drawing.Size(10, ($CustomHeaderPanel.Bottom + 5)) }
            else                   { $MiscPanel.Location = New-Object System.Drawing.Size(10, ($CustomHeaderPanel.Bottom + 5)) }
        }
        if ($GameType.patches)     { $MiscPanel.Location = New-Object System.Drawing.Size(10, ($Patches.Panel.Bottom + 5)) }
    }
    
    $StatusPanel.Location = New-Object System.Drawing.Size(10, ($MiscPanel.Bottom + 5))
    $MainDialog.Height = $StatusPanel.Bottom + 50
    
}



#==============================================================================================================================================================================================
function ChangeGameMode() {
    
    if ($GameType.save -gt 0) { Out-IniFile -FilePath (GetGameSettingsFile) -InputObject $GameSettings | Out-Null }

    Foreach ($Item in $Files.json.games.game) {
        if ($Item.title -eq $CurrentGameComboBox.text) {
            $global:GameType = $Item
            break
        }
    }

    $GameFiles.base = $Paths.games + "\" + $GameType.mode
    $GameFiles.binaries = $GameFiles.base + "\Binaries"
    $GameFiles.extracted = $GameFiles.base + "\Extracted"
    $GameFiles.export = $GameFiles.base + "\Export"
    $GameFiles.compressed = $GameFiles.base + "\Compressed"
    $GameFiles.decompressed = $GameFiles.base + "\Decompressed"
    $GameFiles.downgrade = $GameFiles.base + "\Downgrade"
    $GameFiles.textures = $GameFiles.base + "\Textures"
    $GameFiles.previews = $GameFiles.base + "\Previews"
    $GameFiles.credits = $GameFiles.base + "\Credits.txt"
    $GameFiles.info = $GameFiles.base + "\Info.txt"
    $GameFiles.json = $GameFiles.base + "\Patches.json"

    $global:GameSettings = GetSettings (GetGameSettingsFile)

    # Patches.json
    if (IsSet $GameType.patches) {
        if (TestFile $GameFiles.json) {
            try { $Files.json.patches = Get-Content -Raw -Path $GameFiles.json | ConvertFrom-Json }
            catch { CreateErrorDialog "Corrupted JSON" }
        }
        else { CreateErrorDialog "Missing JSON" }
    }
    
    # Credits.json
    if (TestFile ($GameFiles.previews + "\Credits.json")) {
        try { $Files.json.models = Get-Content -Raw -Path ($GameFiles.previews + "\Credits.json") | ConvertFrom-Json }
        catch { CreateErrorDialog "Corrupted JSON" }
    }
    else { $Files.json.models = $null }

    # Info
    if (TestFile $GameFiles.info)       { AddTextFileToTextbox -TextBox $Credits.Sections[0] -File $GameFiles.info }
    else                                { AddTextFileToTextbox -TextBox $Credits.Sections[0] -File $null }

    # Credits
    if (TestFile $Files.text.credits)   { AddTextFileToTextbox -TextBox $Credits.Sections[1] -File $Files.text.credits }
    if (TestFile $GameFiles.credits)    { AddTextFileToTextbox -TextBox $Credits.Sections[1] -File $GameFiles.credits -Add -PreSpace 2 }

    $CreditsGameLabel.Text = "Current Game: " + $GameType.mode
    $Patches.Panel.Visible = $GameType.patches

    SetModeLabel
    if ($IsActiveGameField) { ChangePatchPanel }
    $global:IsActiveGameField = $True

}



#==============================================================================================================================================================================================
function SetVCPanel() {
    
    # Reset VC panel visibility
    $VC.Group.Controls.GetEnumerator() | ForEach-Object { EnableElem -Elem $_ -Active $False -Hide }
    EnableElem -Elem @($VC.ActionsLabel, $VC.PatchVCButton, $VC.ExtractROMButton) -Active $True -Hide

    # Enable VC panel visiblity
    if ($GameConsole.options_vc -gt 0) {
        if ($GameConsole.t64 -eq 1)                                      { EnableElem -Elem @($VC.RemoveT64, $VC.RemoveT64Label) -Active $True -Hide }
        if ($GameType.patches_vc -gt 0 -or $GameConsole.t64 -eq 1)       { $VC.CoreLabel.Visible = $True }
        if ($GameType.patches_vc -eq 1 -or $GameType.patches_vc -eq 2)   { EnableElem -Elem @($VC.RemoveFilter,$VC.RemoveFilterLabel) -Active $True -Hide }
        if ($GameType.patches_vc -eq 2)                                  { EnableElem -Elem @($VC.RemapL, $VC.RemapLLabel) -Active $True -Hide }
        if ($GameType.patches_vc -ge 3) {
            EnableElem -Elem @($VC.ExpandMemory, $VC.RemapDPad, $VC.RemapCDown, $VC.RemapZ, $VC.ExpandMemoryLabel, $VC.RemapDPadLabel, $VC.RemapCDownLabel, $VC.RemapZLabel) -Active $True -Hide
            $VC.MinimapLabel.Show() 
        }
        if ($GameType.patches_vc -eq 4) { EnableElem -Elem @($VC.LeaveDPadUp, $VC.LeaveDPadUpLabel) -Active $True -Hide }
    }

}



#==============================================================================================================================================================================================
function UpdateStatusLabel([String]$Text) {
    
    WriteToConsole $Text
    $StatusLabel.Text = $Text
    $StatusLabel.Refresh()

}



#==============================================================================================================================================================================================
function WriteToConsole([String]$Text) { if ($Settings.Debug.Console -eq $True) { Write-Host $Text } }



#==============================================================================================================================================================================================
function SetModeLabel() {
	
    $CurrentModeLabel.Text = "Current  Mode  :  " + $GameType.mode
    if ($IsWiiVC) { $CurrentModeLabel.Text += "  (Wii  VC)" } else { $CurrentModeLabel.Text += "  (" + $GameConsole.Mode + ")" }
    $CurrentModeLabel.Location = New-Object System.Drawing.Size(([Math]::Floor($MainDialog.Width / 2) - [Math]::Floor($CurrentModeLabel.Width / 2)), 10)

}



#==================================================================================================================================================================================================================================================================
function EnablePatchButtons([Boolean]$Enable) {
    
    # Set the status that we are ready to roll... Or not...
    if ($Enable)        { UpdateStatusLabel "Ready to patch!" }
    else                { UpdateStatusLabel "Select your ROM or VC WAD file to continue." }

    # Enable patcher buttons.
    $Patches.Panel.Enabled = $Enable

    # Enable ROM extract
    $VC.ExtractROMButton.Enabled = $Enable

}



#==================================================================================================================================================================================================================================================================
function GamePath_Finish([Object]$TextBox, [String]$Path) {
    
    # Set the "GamePath" variable that tracks the path
    $global:GamePath = $Path

    # Update the textbox with the current game
    $TextBox.Text = $GamePath

    # Check if the game is a WAD
    $DroppedExtn = (Get-Item -LiteralPath $GamePath).Extension

    if ( ($DroppedExtn -eq '.wad') -and !$IsWiiVC)              { SetWiiVCMode $True }
    elseif ( ($DroppedExtn -ne '.wad') -and $IsWiiVC)           { SetWiiVCMode $False }
    elseif ( ($DroppedExtn -ne '.wad') -and !$GameIsSelected)   { SetWiiVCMode $False }
    SetMainScreenSize
    $global:GameIsSelected = $True

    ChangeGamesList
    $InputPaths.ClearGameButton.Enabled = $True
    $InputPaths.PatchPanel.Visible = $True
    $CustomHeaderPatchButton.Enabled = $CustomHeaderCheckbox.checked

    # Calculate checksum if Native Mode
    if (!$IsWiiVC) {
        # Update hash
        $HashSumROMTextBox.Text = (Get-FileHash -Algorithm MD5 $GamePath).Hash

        # Verify ROM
        $MatchingROMTextBox.Text = "No Valid ROM Selected"
        Foreach ($Item in $Files.json.games.game) {
            if ($HashSumROMTextBox.Text -eq $Item.hash) {
              $MatchingROMTextBox.Text = $Item.title + " (Rev 0)"
              break
            }
            for ($i = 0; $i -lt $Item.downgrade.length; $i++) {
              if ($HashSumROMTextBox.Text -eq $Item.downgrade[$i].hash) {
                   $MatchingROMTextBox.Text = $Item.title + " (" +  $Item.downgrade[$i].rev + ")"
                    break
                }
            }
        }
    }
    else {
        $HashSumROMTextBox.Text = ""
        $MatchingROMTextBox.Text = "No checksums for WAD files"
    }

}



#==================================================================================================================================================================================================================================================================
function InjectPath_Finish([Object]$TextBox, [String]$Path) {
    
    # Set the "InjectPath" variable that tracks the path
    $global:InjectPath = $Path

    # Update the textbox to the current injection ROM
    $TextBox.Text = $InjectPath

    $InputPaths.ApplyInjectButton.Enabled = $True

}



#==================================================================================================================================================================================================================================================================
function PatchPath_Finish([Object]$TextBox, [String]$Path) {
    
    # Set the "PatchPath" variable that tracks the path
    $global:PatchPath = $Path

    # Update the textbox to the current patch
    $TextBox.Text = $PatchPath

    $InputPaths.ApplyPatchButton.Enabled = $True

}



#==============================================================================================================================================================================================
function GetHeader() {
    
    if ($IsWiiVC) {
        if (IsSet $GamePatch.vc_title)     { $CustomTitleTextBox.Text  = $GamePatch.vc_title }
        else                               { $CustomTitleTextBox.Text  = $GameType.vc_title }
        if (IsSet $GamePatch.vc_gameID)    { $CustomGameIDTextBox.Text = $GamePatch.vc_gameID }
        else                               { $CustomGameIDTextBox.Text = $GameType.vc_gameID }
    }
    else {
        if (IsSet $GamePatch.rom_title)    { $CustomTitleTextBox.Text  = $GamePatch.rom_title }
        else                               { $CustomTitleTextBox.Text  = $GameType.rom_title }
        if (IsSet $GamePatch.rom_gameID)   { $CustomGameIDTextBox.Text = $GamePatch.rom_gameID }
        else                               { $CustomGameIDTextBox.Text = $GameType.rom_gameID }
        if (IsSet $GamePatch.rom_region)   { $CustomRegionCodeComboBox.SelectedIndex = $GamePatch.rom_region }
        else                               { $CustomRegionCodeComboBox.SelectedIndex = $GameType.rom_region }
    }

}



#==============================================================================================================================================================================================
function IsChecked([Object]$Elem, [Switch]$Not) {
    
    if (!(IsSet $Elem))   { return $False }
    if (!$Elem.Active)    { return $False }
    if ($Elem.Checked)    { return !$Not  }
    if (!$Elem.Checked)   { return $Not   }
    return $False

}



#==============================================================================================================================================================================================
function IsLanguage([Object]$Elem, [int]$Lang=0) {
    
    if (!$Redux.Language[$Lang].Checked)   { return $False }
    if (IsChecked $Elem)                   { return $True  }
    return $False

}



#==============================================================================================================================================================================================
function IsText([Object]$Elem, [String]$Compare, [Switch]$Active, [Switch]$Not) {
    
    $Text = $Elem.Text.replace(" (default)", "")
    if (!(IsSet $Elem))                 { return $False }
    if ($Active -and !$Elem.Visible)    { return $False }
    if (!$Active -and !$Elem.Enabled)   { return $False }
    if ($Text -eq $Compare)             { return !$Not  }
    if ($Text -ne $Compare)             { return $Not   }
    return $False

}



#==============================================================================================================================================================================================
function IsLangText([Object]$Elem, [String]$Compare, [int]$Lang=0) {
    
    if (!$Redux.Language[$Lang].Checked)        { return $False }
    if (IsText -Elem $Elem -Compare $Compare)   { return $True  }
    return $False

}



#==============================================================================================================================================================================================
function IsIndex([Object]$Elem, [int]$Index=1, [String]$Text, [Switch]$Active, [Switch]$Not) {
    
    if ($Index -lt 1) { $Index = 1 }
    if (!(IsSet $Elem))                       { return $False }
    if ($Active -and !$Elem.Visible)          { return $False }
    if (!$Active -and !$Elem.Enabled)         { return $False }

    if (IsSet $Text) {
        $Text = $Text.replace(" (default)", "")
        if ($Elem.indexOf($Text))             { return !$Not  }
        if (!$Elem.indexOf($Text))            { return $Not   }
    }

    if ($Elem.SelectedIndex -eq ($Index-1))   { return !$Not  }
    if ($Elem.SelectedIndex -ne ($Index-1))   { return $Not   }

    return $False

}



#==============================================================================================================================================================================================
function IsSet([Object]$Elem, [int]$Min, [int]$Max, [int]$MinLength, [int]$MaxLength, [Switch]$HasInt) {

    if ($Elem -eq $null -or $Elem -eq "")                                               { return $False }
    if (!$HasInt -and $Elem -eq 0)                                                      { return $False }
    if ($Min -ne $null -and $Min -ne "" -and [int]$Elem -lt $Min)                       { return $False }
    if ($Max -ne $null -and $Max -ne "" -and [int]$Elem -gt $Max)                       { return $False }
    if ($MinLength -ne $null -and $MinLength -ne "" -and $Elem.Length -lt $MinLength)   { return $False }
    if ($MaxLength -ne $null -and $MaxLength -ne "" -and $Elem.Length -gt $MaxLength)   { return $False }

    return $True

}



#==============================================================================================================================================================================================
function AddTextFileToTextbox([Object]$TextBox, [String]$File, [Switch]$Add, [int]$PreSpace, [int]$PostSpace) {
    
    if (!(IsSet $File)) {
        $TextBox.Text = ""
        return
    }

    if (TestFile $File) {
        $str = ""
        for ($i=0; $i -lt (Get-Content $File).Count; $i++) {
            if ((Get-Content $File)[$i] -ne "") {
                $str += (Get-Content $File)[$i]
                if ($i -lt  (Get-Content $File).Count-1) { $str += "{0}" }
            }
            else { $str += "{0}" }
        }

        if ($PreSpace -gt 0) {
            for ($i=0; $i -lt $PreSpace; $i++) { $str = "{0}" + $str }
        }
        if ($PostSpace -gt 0) {
            for ($i=0; $i -lt $PostSpace; $i++) { $str = $str + "{0}" }
        }

        $str = [String]::Format($str, [Environment]::NewLine)

        if ($Add) { $TextBox.Text += $str }
        else      { $TextBox.Text = $str }
    }

}



#==============================================================================================================================================================================================
function GetFilePaths() {
    
    if (IsSet $Settings["Core"][$InputPaths.GameTextBox.Name]) {
        if (TestFile $Settings["Core"][$InputPaths.GameTextBox.Name]) {
            GamePath_Finish $InputPaths.GameTextBox -VarName $InputPaths.GameTextBox.Name -Path $Settings["Core"][$InputPaths.GameTextBox.Name]
        }
        else { $InputPaths.GameTextBox.Text = "Select or drag and drop your ROM or VC WAD file..." }
    }

    if (IsSet $Settings["Core"][$InputPaths.InjectTextBox.Name]) {
        if (TestFile $Settings["Core"][$InputPaths.InjectTextBox.Name]) {
            InjectPath_Finish $InputPaths.InjectTextBox -VarName $InputPaths.InjectTextBox.Name -Path $Settings["Core"][$InputPaths.InjectTextBox.Name]
        }
        else { $InputPaths.InjectTextBox.Text = "Select or drag and drop your NES, SNES or N64 ROM..." }
    }

    if (IsSet $Settings["Core"][$InputPaths.PatchTextBox.Name]) {
        if (TestFile $Settings["Core"][$InputPaths.PatchTextBox.Name]) {	
            PatchPath_Finish $InputPaths.PatchTextBox -VarName $InputPaths.PatchTextBox.Name -Path $Settings["Core"][$InputPaths.PatchTextBox.Name]
        }
        else { $InputPaths.PatchTextBox.Text = "Select or drag and drop your BPS, IPS, Xdelta, VCDiff or PPF Patch File..." }
    }

}



#==============================================================================================================================================================================================
function RestoreCustomHeader() {
    
    if (IsChecked $CustomHeaderCheckbox) {
        if (IsSet $Settings["Core"]["CustomTitle"]) {
            $CustomTitleTextBox.Text  = $Settings["Core"]["CustomTitle"]
        }
        if (IsSet $Settings["Core"]["CustomGameID"]) {
            $CustomGameIDTextBox.Text = $Settings["Core"]["CustomGameID"]
        }
        if (IsSet $Settings["Core"]["CustomRegionCode"]) {
            $CustomRegionCodeComboBox.SelectedIndex = $Settings["Core"]["CustomRegionCode"]
        }
    }
    else { GetHeader }

    $CustomGameIDTextBox.Enabled = $CustomTitleTextBox.Enabled = $CustomRegionCodeComboBox.Enabled = $CustomHeaderCheckbox.Checked
    $CustomHeaderPatchButton.Enabled = (IsSet -Elem GamePath) -and $CustomHeaderCheckbox.Checked

}



#==============================================================================================================================================================================================
function StrLike([String]$Str, [String]$Val, [Switch]$Not) {
    
    if     ($str.ToLower() -like "*"    + $val + "*")   { return !$Not }
    elseif ($str.ToLower() -notlike "*" + $val + "*")   { return $Not }
    return $False

}



#==============================================================================================================================================================================================
function EnableGUI([Boolean]$Enable) {
    
    $InputPaths.GamePanel.Enabled = $InputPaths.InjectPanel.Enabled = $InputPaths.PatchPanel.Enabled = $Enable
    $CurrentGamePanel.Enabled = $CustomHeaderPanel.Enabled = $Enable
    $Patches.Panel.Enabled = $MiscPanel.Enabled = $VC.Panel.Enabled = $Enable

}



#==============================================================================================================================================================================================
function EnableForm([Object]$Form, [Boolean]$Enable, [Switch]$Not) {
    
    if ($Not) { $Enable = !$Enable }
    if ($Form.Controls.length -eq $True) {
        $Form.Controls.GetEnumerator() | ForEach-Object { $_.Enabled = $Enable }
    }
    else { $Form.Enabled = $Enable }

}



#==============================================================================================================================================================================================
function EnableElem([Object]$Elem, [Boolean]$Active=$True, [Switch]$Hide) {

    if ($Elem -is [system.Array]) {
        foreach ($Obj in $Elem) {
            $Obj.Enabled = $Obj.Active = $Active
            if ($Hide) { $Obj.Visible = $Active }
        }
    }
    else {
        $Elem.Enabled = $Elem.Active = $Active
        if ($Hide) { $Elem.Visible = $Active }
    }

}



#==============================================================================================================================================================================================
function GetFileName([String]$Path, [String]$Description, [String[]]$FileNames) {
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $Path
    
    $FilterString = $Description + "|"
    for($i = 0; $i -lt $FileNames.Count; $i++) {
        $FilterString += $FileNames[$i] + ';'
    }
    $FilterString += "|All Files|(*.*)"

    $OpenFileDialog.Filter = $FilterString.TrimEnd('|')
    $OpenFileDialog.ShowDialog() | Out-Null
    
    return $OpenFileDialog.FileName

}



#==============================================================================================================================================================================================
function RemovePath([String]$Path) {
    
    # Make sure the path isn't null to avoid errors
    if ($Path -ne '') {
        # Check to see if the path exists
        if (TestFile -Path $Path -Container) {
            # Remove the path
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction 'SilentlyContinue' | Out-Null
        }
    }

}



#==============================================================================================================================================================================================
function CreatePath([String]$Path) {
    
    # Make sure the path is not null to avoid errors
    if ($Path -ne '') {
        # Check to see if the path does not exist
        if (!(TestFile -Path $Path -Container)) {
            # Create the path.
            New-Item -Path $Path -ItemType 'Directory' | Out-Null
        }
    }

    # Return the path so it can be set to a variable when creating
    return $Path

}



#==============================================================================================================================================================================================
function RemoveFile([String]$Path) {
    
    if (TestFile $Path)   { Remove-Item -LiteralPath $Path -Force }

}



#==============================================================================================================================================================================================
function TestFile([String]$Path, [Switch]$Container) {
    
    if ($Container)   { return Test-Path -LiteralPath $Path -PathType Container }
    else              { return Test-Path -LiteralPath $Path -PathType Leaf }

}



#==============================================================================================================================================================================================
function CreateSubPath([String]$Path) {

    if (!(TestFile -Path $Path -Container)) {
        New-Item -Path $Path.substring(0, $Path.LastIndexOf('\')) -Name $Path.substring($Path.LastIndexOf('\') + 1) -ItemType Directory | Out-Null
    }

}



#==============================================================================================================================================================================================
function ShowPowerShellConsole([bool]$Show) {
    
    # Sshows or hide the console window
    switch ($Show) {
        $True   { [Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 5) | Out-Null }
        $False  { [Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0) | Out-Null }
    }

}



#==================================================================================================================================================================================================================================================================
function TogglePowerShellOpenWithClicks([Boolean]$Enable) {
    
    # Create a temporary folder to create the registry entry and and set the path to it
    RemovePath $Paths.Registry
    CreatePath $Paths.Registry
    $RegFile = $Paths.Registry + "\Double Click.reg"

    # Create the registry file.
    Add-Content -LiteralPath $RegFile -Value 'Windows Registry Editor Version 5.00'
    Add-Content -LiteralPath $RegFile -Value ''
    Add-Content -LiteralPath $RegFile -Value '[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Microsoft.PowerShellScript.1\Shell]'

    # Get the current state of the value in the registry.
    $PS_DC_State = (Get-ItemProperty -LiteralPath "HKLM:\Software\Classes\Microsoft.PowerShellScript.1\Shell").'(default)'

    # Check the current state and add the value to the registry
    switch ($PS_DC_State) {
        # A "0" means that a script won't automatically launch with PowerShell so change it to "Open"
        '0'     { Add-Content -LiteralPath $RegFile -Value '@="Open"' }
        default { Add-Content -LiteralPath $RegFile -Value '@="0"' }
    }

    # Execute the registry file.
    & regedit /s $RegFile

}


#==================================================================================================================================================================================================================================================================
function SetFunctionTitle([String]$Function) {

    $Function = $Function -replace " ", ""
    $Function = $Function -replace ",", ""
    $Function = $Function -replace "'", ""
    return $Function

}



#==============================================================================================================================================================================================

Export-ModuleMember -Function SetWiiVCMode
Export-ModuleMember -Function SetVCPanel
Export-ModuleMember -Function CreateToolTip
Export-ModuleMember -Function ChangeConsolesList
Export-ModuleMember -Function ChangeGamesList
Export-ModuleMember -Function ChangePatchPanel
Export-ModuleMember -Function SetMainScreenSize
Export-ModuleMember -Function ChangeGameMode
Export-ModuleMember -Function UpdateStatusLabel
Export-ModuleMember -Function WriteToConsole
Export-ModuleMember -Function SetModeLabel
Export-ModuleMember -Function EnablePatchButtons

Export-ModuleMember -Function GamePath_Finish
Export-ModuleMember -Function InjectPath_Finish
Export-ModuleMember -Function PatchPath_Finish

Export-ModuleMember -Function GetHeader
Export-ModuleMember -Function IsChecked
Export-ModuleMember -Function IsLanguage
Export-ModuleMember -Function IsText
Export-ModuleMember -Function IsLangText
Export-ModuleMember -Function IsIndex
Export-ModuleMember -Function IsSet
Export-ModuleMember -Function AddTextFileToTextbox
Export-ModuleMember -Function StrLike
Export-ModuleMember -Function GetFilePaths
Export-ModuleMember -Function RestoreCustomHeader
Export-ModuleMember -Function EnableGUI
Export-ModuleMember -Function EnableForm
Export-ModuleMember -Function EnableElem

Export-ModuleMember -Function GetFileName
Export-ModuleMember -Function RemoveFile
Export-ModuleMember -Function RemovePath
Export-ModuleMember -Function CreatePath
Export-ModuleMember -Function RemoveFile
Export-ModuleMember -Function TestFile
Export-ModuleMember -Function CreateSubPath

Export-ModuleMember -Function ShowPowerShellConsole
Export-ModuleMember -Function TogglePowerShellOpenWithClicks
Export-ModuleMember -Function SetFunctionTitle
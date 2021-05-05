Import-Module ActiveDirectory

$dateStamp = Get-Date -Format MMddyyyy_HHmmss
$outputFilePath = ".\AcronisSystemCount-$dateStamp.csv"
$errorLogFilePath_CD = ".\AcronisSystemCount_ErrorLog-$dateStamp.txt"    

Get-ADComputer -filter { OperatingSystem -like "*Windows*" } | select-object name -OutVariable Nodes >$null
$Nodes | ForEach-Object {
    $currComp = $_.Name
    Try {
        
        $os = (Get-WmiObject -ComputerName $_.Name -Class 'Win32_OperatingSystem' -ErrorAction Stop).Caption
        get-wmiobject -ComputerName $_.Name -class 'win32_computersystem' |
        Select-Object -Property Name, @{ n = "Operating System" ; e = { $os }}, Model
    }
    Catch { 
        Try {
            Get-ADComputer -filter { Name -eq $currComp } -Properties OperatingSystem | 
            Select-Object Name, @{ n = "Operating System" ; e = { $_.OperatingSystem }}, @{ n = "Model" ; e = { "Unavailable" }}
        }
        Catch { Add-Content -Path  $errorLogFilePath_CD -Value "$($currComp): $_.Exception.Message" }
    }
} | Sort-Object Name -OutVariable Export

$Export | export-CSV -Path $outputFilePath -NoTypeInformation
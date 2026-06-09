#Official TLD list : https://data.iana.org/TLD/tlds-alpha-by-domain.txt

#Get site to test
$Name = Read-Host "What is the name to test ?"

#Get TLDs
$tldListPath = Join-Path $PSScriptRoot -ChildPath "tldList.txt"
$tlds = Get-Content $tldListPath


$FinalList = [System.Collections.Concurrent.ConcurrentBag[string]]::new()

#Check every tld for site
$tlds | ForEach-Object -Parallel {
    $tld = $_
    if ([string]::IsNullOrWhiteSpace($tld) -or $tld.StartsWith("#")) { return }

    $siteUrl = "https://$using:Name.$tld"
    try {
        $response = Invoke-RestMethod -Uri $siteUrl -StatusCodeVariable "httpStatus" -SkipHttpErrorCheck -ErrorAction Stop
        
        if ($httpStatus -eq 200) {
            Write-Host "$siteUrl -> Status Code: $httpStatus (Success!)" -BackgroundColor Green -ForegroundColor White
            ($using:FinalList).Add($siteUrl)
        }
        elseif ($httpStatus -gt 0) {
            Write-Host "$siteUrl -> Status Code: $httpStatus" -BackgroundColor Red -ForegroundColor Black
        }
        }
    catch {

    }
}
    

Write-Host "`n`n Here is the list of site you should check : $($FinalList)"
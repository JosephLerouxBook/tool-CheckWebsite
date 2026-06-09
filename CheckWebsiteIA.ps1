
# Get site to test
$Name = Read-Host "What is the name to test ?"

# Get TLDs
$tldListPath = Join-Path $PSScriptRoot -ChildPath "tldList.txt"
$tlds = Get-Content $tldListPath

# Thread-safe list for parallel processing
$WorkingDomains = [System.Collections.Concurrent.ConcurrentBag[string]]::new()

Write-Host "`nStarting incredibly fast PS7 multi-threaded scan...`n" -ForegroundColor Cyan

# The magic -Parallel parameter! 
$tlds | ForEach-Object -Parallel {
    $tld = $_
    if ([string]::IsNullOrWhiteSpace($tld) -or $tld.StartsWith("#")) { return }

    # Notice we use $using:Name to pull the variable from outside the parallel block
    $siteUrl = "https://$using:Name.$tld"
    
    try {
        # In PS7, we get our beautiful -StatusCodeVariable and -SkipHttpErrorCheck back!
        $response = Invoke-RestMethod -Uri $siteUrl -StatusCodeVariable "httpStatus" -SkipHttpErrorCheck -ErrorAction Stop
        
        if ($httpStatus -eq 200) {
            Write-Host "$siteUrl -> Status Code: $httpStatus (Success!)" -BackgroundColor Green -ForegroundColor White
            $WorkingDomains.Add($siteUrl)
        }
        elseif ($httpStatus -gt 0) {
            Write-Host "$siteUrl -> Status Code: $httpStatus" -BackgroundColor Red -ForegroundColor Black
        }
    } 
    catch {
        # Silent fail for unregistered domains so they don't clog up the screen
    }
} -ThrottleLimit 20 

# ThrottleLimit 20 means it checks 20 domains simultaneously

Write-Host "`nScan Complete! Found $($WorkingDomains.Count) working domains." -ForegroundColor Cyan
Write-Host "Here is the list of sites you should check:`n$($WorkingDomains -join "`n")"
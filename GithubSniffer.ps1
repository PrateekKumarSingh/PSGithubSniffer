[cmdletbinding()]
param()

$APIEndpoint = 'http://api.github.com'
$IntervalInMins = 60
$Header = @{Authorization = 'Basic {0}' -f [System.Convert]::ToBase64String([char[]]'77ebf963bdc0d369755c1948b651f9c7dc6d2d9d')}

$SplatParam = @{
                Header  = $Header
                uri     = "$APIEndpoint/search/repositories?q=language:powershell&sort=updated&per_page=10000"
                Method  = 'GET'
}

Function GitHubDirectoryRecurse ($Items)
{
        Foreach($Item in $Items)
        {
                if($item.type -eq 'dir'){
                        Invoke-RestMethod -Uri $Item.url | ForEach-Object {
                                If($_.type -eq 'dir'){
                                        GitHubDirectoryRecurse $_
                                }
                                else {
                                        $_.download_url
                                }
                        }
                }
                if($item.type -eq 'file'){
                        $Item.download_url
                }
        }
}

#$PSRepo = Invoke-RestMethod @SplatParam | Select-Object -ExpandProperty Items | Select-Object -f 1
#Pagination logic incase results are more than hundred
Write-Verbose "Searching GitHub repositories..."
$PSRepo = (Invoke-RestMethod @SplatParam).items | Where-Object {[Datetime]$_.updated_at -gt (Get-Date).AddMinutes(-$IntervalInMins)}
Write-Verbose "Total: $($PSRepo.Count) repositories found"

Write-Host "Following Powershell repositories on GitHub were updated in Last $IntervalInMins minutes" -ForegroundColor Green
$PSRepo | Select-Object @{n='RepositoryURL';e={$_.html_url}},`
                        @{n='UpdateDateTime(UTC)';e={$_.updated_at}},`
                        Description |Format-Table -AutoSize -Wrap

Write-Verbose "Extracting raw file(s) URL from each repository..."
Foreach($Repo in $PSRepo)
{
        $PSRepoContent  = Invoke-RestMethod -Uri ($Repo.url + "/contents")
        GitHubDirectoryRecurse $PSRepoContent
}


Invoke-RestMethod https://api.github.com/repos/sarunasil/Puslapis/contents/labas?ref=master
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Slug,

    [Parameter(Position = 1)]
    [ValidateSet("cn", "en")]
    [string]$Language = "cn"
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$url = "https://developer.huawei.com/consumer/$Language/doc/$Slug.md"
$response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30

if ($response.StatusCode -eq 200) {
    $safeName = $Slug -replace '/', '__'
    $outPath = Join-Path $env:TEMP "harmonyos-doc-$safeName.md"
    $response.Content | Out-File -FilePath $outPath -Encoding UTF8
    Write-Output $outPath
} else {
    Write-Error "HTTP $($response.StatusCode): $url"
}

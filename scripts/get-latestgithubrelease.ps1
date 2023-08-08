param(
  [Parameter(Mandatory = $true)]
  [string]$GitHubOwner,
  [Parameter(Mandatory = $true)]
  [string]$RepoName,
  [Parameter(Mandatory = $true)]
  [string]$OSTagPrefix,
  [Parameter(Mandatory = $true)]
  [bool]$IncludePreRelease
)


function Get-GitHubReleases {
  param(
    [string]$GitHubOwner,
    [string]$RepoName
  )

  $apiUrl = "https://api.github.com/repos/$GitHubOwner/$RepoName/releases"
  $headers = @{
    'User-Agent' = 'PowerShell'
  }

  try {
    $releases = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
    return $releases
  }
  catch {
    Write-Host 'Error: Unable to retrieve GitHub releases.'
    return $null
  }
}

function Get-LatestGithubRelease {
  param(
    [Parameter(Mandatory = $true)]
    [string]$GitHubOwner,
    [Parameter(Mandatory = $true)]
    [string]$RepoName,
    [Parameter(Mandatory = $true)]
    [string]$OSTagPrefix,
    [Parameter(Mandatory = $true)]
    [bool]$IncludePreRelease
  )

  $releases = Get-GitHubReleases -GitHubOwner $githubOwner -RepoName $repoName

  $filteredreleases = @()
  if ($releases) {
    $releases | ForEach-Object {
      if ($OSTagPrefix -eq $null -or $_.tag_name -like "*$OSTagPrefix*") {
        $filteredreleases += $_
      }
    }
    if (!$IncludePreRelease) {
      $filteredreleases = $filteredreleases | Where-Object { $_.prerelease -eq $false }
    }

    $latest_release = $filteredreleases | Sort-Object -Property published_at -Descending | Select-Object -First 1
  }
  else {
    Write-Output 'Unable to retrieve GitHub releases.'
  }

  if ($latest_release) {
    $output_object = @{
      'tag_name'         = $latest_release.tag_name
      'name'             = $latest_release.name
      'published_at'     = $latest_release.published_at
      'url'              = $latest_release.url
      'target_commitish' = $latest_release.target_commitish
      'prerelease'       = $latest_release.prerelease
    }
    Write-Output $output_object
  }
  else {
    Write-Output 'Unable to retrieve GitHub releases.'
  }
}

Get-LatestGithubRelease -OSTagPrefix $OSTagPrefix -GitHubOwner $GitHubOwner -RepoName $RepoName -IncludePreRelease $IncludePreRelease

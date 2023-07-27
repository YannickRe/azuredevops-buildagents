param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('win19', 'win22', 'ubuntu22', 'ubuntu20')]
  [string]$OSTagPrefix
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
    [string]$GitHubOwner = 'actions',
    [string]$RepoName = 'runner-images',
    [Parameter(Mandatory = $true)]
    [ValidateSet('win19', 'win22', 'ubuntu22', 'ubuntu20')]
    [string]$OSTagPrefix
  )

  $releases = Get-GitHubReleases -GitHubOwner $githubOwner -RepoName $repoName

  $filteredreleases = @()
  if ($releases) {
    $releases | ForEach-Object {
      if ($OSTagPrefix -eq $null -or $_.tag_name -like "*$OSTagPrefix*") {
        $filteredreleases += $_
      }
    }

    $latest_release = $filteredreleases | Sort-Object -Property published_at -Descending | Select-Object -First 1
  }
  else {
    Write-Output 'Unable to retrieve GitHub releases.'
  }

  if ($latest_release) {
    $output_object = @{
      'tag_name'         = $latest_release.tag_name
      'published_at'     = $latest_release.published_at
      'url'              = $latest_release.url
      'target_commitish' = $latest_release.target_commitish
    }
    Write-Output $output_object
  }
  else {
    Write-Output 'Unable to retrieve GitHub releases.'
  }
}

Get-LatestGithubRelease -OSTagPrefix $OSTagPrefix

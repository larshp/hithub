$ErrorActionPreference = 'Stop'

$revision = 'b4eb6c7baf81a78f2ce10e0d86ecb3b6bbe7b39f'
$repository = 'https://github.com/abapGit/abapGit.git'
$dependency = Join-Path $PSScriptRoot 'deps\abapgit'

if (Test-Path -LiteralPath $dependency) {
  $actual = (git -C $dependency rev-parse HEAD).Trim()
  if ($actual -ne $revision) {
    throw "abapGit dependency is at $actual; expected $revision"
  }
  Write-Output "abapGit dependency already pinned at $actual"
  exit 0
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dependency) | Out-Null
git clone --quiet --branch v1.134.0 --single-branch $repository $dependency

$actual = (git -C $dependency rev-parse HEAD).Trim()
if ($actual -ne $revision) {
  throw "abapGit checkout resolved to $actual; expected $revision"
}

Write-Output "abapGit dependency pinned at $actual"

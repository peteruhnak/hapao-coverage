[CmdletBinding(DefaultParameterSetName="A")]

param (
    [Parameter(Mandatory=$true)][string] $Repository,
    [Parameter(Mandatory=$true, ParameterSetName="A")][string] $AccessKey,
    [Parameter(Mandatory=$true, ParameterSetName="A")][string] $SecretKey,
    [Parameter(Mandatory=$true, ParameterSetName="B")][string] $AccessKeysCsv
)

function Encrypt($Key) {
    Push-Location $Repository
    $Encrypted = Invoke-Expression "travis encrypt $Key"
    Pop-Location
    return $Encrypted
}

if ($AccessKeysCsv) {
    $Contents = (Import-Csv $AccessKeysCsv -Header @("id", "key"))[-1]
    $AccessKey = $Contents.id
    $SecretKey = $Contents.key
}

$EncAccessKey = Encrypt($AccessKey)
$EncSecretKey = Encrypt($SecretKey)

Add-Content $Repository\.travis.yml "`n
cache:
  directories:
    - `$SMALLTALK_CI_BUILD_BASE/pharo-local/package-cache

after_success:
  - wget -O- https://raw.githubusercontent.com/peteruhnak/hapao-coverage/master/hapao-coverage.sh | bash

deploy:
  provider: s3
  access_key_id:
    secure: $EncAccessKey
  secret_access_key:
    secure: $EncSecretKey
  bucket: 'hapao-coverage.peteruhnak-com'
  region: eu-central-1
  local_dir: coverage-result
  upload-dir: `$TRAVIS_REPO_SLUG/`$TRAVIS_BUILD_NUMBER
  skip-cleanup: true
  on:
    branch: master"
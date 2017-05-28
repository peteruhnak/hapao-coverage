param (
    [Parameter(Mandatory=$true)][string] $Repository,
    [Parameter(Mandatory=$true)][string] $AccessKey,
    [Parameter(Mandatory=$true)][string] $SecretKey
)

function Encrypt($Key) {
    Push-Location $Repository
    $Encrypted = Invoke-Expression "travis encrypt $Key"
    Pop-Location
    return $Encrypted
}

$EncAccessKey = Encrypt($AccessKey)
$EncSecretKey = Encrypt($SecretKey)

Add-Content $Repository\.travis.yml "`n
cache:
  directories:
    `$HOME/package-cache

before_script:
  - wget -O- https://raw.githubusercontent.com/peteruhnak/hapao-coverage/master/package-cache.sh | bash

after_success:
  - wget -O- https://raw.githubusercontent.com/peteruhnak/hapao-coverage/master/hapao-coverage.sh | bash

deploy:
  provider: s3
  access_key_id:
    secure: $EncAccessKey
  secret_access_key:
    secure: $EncSecretKey
  bucket: 'gh-coverage-peteruhnak-com'
  region: eu-central-1
  local_dir: coverage-result
  upload-dir: `$TRAVIS_REPO_SLUG/`$TRAVIS_BUILD_NUMBER
  skip-cleanup: true
  on:
    branch: master"
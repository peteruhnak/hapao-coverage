# Experimental Hapao-based Coverage for Travis

A bunch of scripts to run hapao coverage on Travis and upload results to S3.
Package cache included.

Experimental... anything can change at any moment.

## Hapao Coverage

hapao: http://hapao.dcc.uchile.cl/ , http://forum.world.st/ANN-Test-Coverage-with-Hapao-td4778403.html

run hapao coverage, export it to html and upload to S3 bucket

The coverage script installs more packages, however it uses a its own copy of the image, so the actual built image is not changed.


1. provide encrypted access keys to S3 bucket

```
travis encrypt KEY
```

note: `--add` option will break the formatting, so maybe

```
travis encrypt KEY >> .travis.yml
```

2. change the bucket name and region

```
bucket: "your-bucket-name"
region: eu-central-1
```

3. change the bucket dir

for project `openponk/xmi` and build `20` this will create a folder `openponk/xmi/20`

```yaml
upload-dir: $TRAVIS_REPO_SLUG/$TRAVIS_BUILD_NUMBER
```

For matrix builds using `$TRAVIS_JOB_NUMBER` is preferable, as all jobs share the same build number

e.g. `openponk/xmi/14.1` and `openponk/xmi/14.2`

```yaml
upload-dir: $TRAVIS_REPO_SLUG/$TRAVIS_JOB_NUMBER
```

## Example .travis.yml (Travis CI)

```yaml
language: smalltalk
sudo: false

os:
  - linux

smalltalk:
  - Pharo-6.0

cache:
  directories:
    - $SMALLTALK_CI_BUILD_BASE/pharo-local/package-cache

after_success:
  - wget -O- https://raw.githubusercontent.com/peteruhnak/hapao-coverage/master/hapao-coverage.sh | bash

deploy:
  provider: s3
  access_key_id:
    secure: ENCRYPTED
  secret_access_key:
    secure: ENCRYPTED
  bucket: "your-bucket-name"
  region: eu-central-1
  local_dir: coverage-result
  upload-dir: $TRAVIS_REPO_SLUG/$TRAVIS_BUILD_NUMBER
  skip-cleanup: true
  on:
    branch: master
```

## Example .gitlab-ci.yml (GitLab Runner)

```yaml
variables:
  DEFAULT_DEPS: "libc6:i386 libuuid1:i386 libfreetype6:i386 libssl1.0.0:i386"
  PHARO_DEPS: "$DEFAULT_DEPS libcairo2:i386"

before_script:
  # Set 32bit and update apt
  - sudo dpkg --add-architecture i386
  - sudo apt-get update -yqq
  # Install dependencies
  - echo "Installing dependencies"
  - sudo apt-get install -y --no-install-recommends $PHARO_DEPS
  # Install smalltalkCI
  - pushd $HOME > /dev/null
  - echo 'Downloading and extracting smalltalkCI'
  - wget -q -O smalltalkCI.zip https://github.com/hpi-swa/smalltalkCI/archive/master.zip
  - unzip -q -o smalltalkCI.zip
  - pushd smalltalkCI-* > /dev/null
  - source env_vars
  - popd > /dev/null
  - popd > /dev/null

stages:
  - build
  - deploy

build:
  stage: build
  script:
    - $SMALLTALK_CI_HOME/run.sh -s "Pharo-6.0"

deploy:

```

(powershell)

```ps
Set-PSReadlineOption -HistorySaveStyle SaveNothing
configure-hapao.ps1 -Repository Z:\Path\To\Repo -AccessKey KEY -SecretKey KEY
```

or use CSV file with credentials exported from AWS

```ps
configure-hapao.ps1 -Repository Z:\Path\To\Repo -AccessKeysCsv Z:\Path\To\AccessKeys.csv
```

the script will ask interactively if the options were not provided

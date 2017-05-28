# Experimental Hapao-based Coverage for Travis

A bunch of scripts to run hapao coverage on Travis and upload results to S3.
Package cache included.

Experimental... anything can change at any moment.

## Package Cache

configure package cache (.mcz files are preserved between builds)

```yaml
cache:
  directories:
    $HOME/package-cache

before_script:
  - wget -O- https://raw.githubusercontent.com/peteruhnak/hapao-coverage/master/package-cache.sh | bash
```

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


## Example .travis.yml

```yaml
language: smalltalk
sudo: false

os:
  - linux

smalltalk:
  - Pharo-6.0

cache:
  directories:
    $HOME/package-cache

before_script:
  - wget -O- https://raw.githubusercontent.com/peteruhnak/hapao-coverage/master/package-cache.sh | bash

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


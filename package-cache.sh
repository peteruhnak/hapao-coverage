#!/usr/bin/env bash

set -eu

mkdir -p $HOME/.config/pharo
mkdir -p $HOME/package-cache

echo "StartupPreferencesLoader default executeAtomicItems: {
        StartupAction
                name: 'Cache'
                code: [
                        MCCacheRepository cacheDirectory: FileLocator home asFileReference / 'package-cache'.
                ]
                runOnce: false
}." > $HOME/.config/pharo/default-package-cache.st
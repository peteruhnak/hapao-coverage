#!/usr/bin/env bash

set -eu

SMALLTALK_VM="$(find $SMALLTALK_CI_VMS -name pharo -type f -executable | head -n 1) --nodisplay"

readonly COVERAGE_DIR=$(readlink -m $(dirname $SMALLTALK_CI_IMAGE))
readonly COVERAGE_IMAGE=$COVERAGE_DIR/coverage.image
readonly BUILD_DIR=${TRAVIS_BUILD_DIR:-$CI_PROJECT_DIR}

copy_image() {
	$SMALLTALK_VM $SMALLTALK_CI_IMAGE save coverage
}

run_coverage() {
	$SMALLTALK_VM $COVERAGE_IMAGE eval "
|buildDir coverageDir confFile conf runCoverage pkgsMatching|
Transcript logCr:  MCCacheRepository cacheDirectory.

Gofer new smalltalkhubUser: 'ObjectProfile' project: 'Spy2'; configurationOf: 'Spy2'; loadBleedingEdge.

buildDir := '$BUILD_DIR' asFileReference.
coverageDir := buildDir / 'coverage-result'.
confFile := buildDir / '.smalltalk.ston'.
conf := SmalltalkCISpec fromStream: confFile readStream.

runCoverage := [ :runName :pkgs | |coverage view pkgDir|
	coverage := Hapao2 runTestsForPackages: pkgs.
	view := RTView new.
	view canvas theme: TRWhiteTheme new.
	view @ RTDraggableView @ RTZoomableView.
	coverage visualizeOn: view.
	pkgDir := coverageDir / runName.
	pkgDir ensureCreateDirectory.
	RTHTML5Exporter new
		directory: pkgDir;
		export: view.
].

pkgsMatching := [ :regex |
	RPackage organizer packages select: [ :each | each name matchesRegex: regex ].
].

conf coverageDictionary at: #packages ifPresent: [ :pkgNames |
	pkgNames do: [ :pkgName |
		(pkgsMatching value: pkgName) do: [ :pkg | runCoverage value: pkg name value: { pkg } ].
	].
	true ifTrue: [ |pkgs|
		pkgs := OrderedCollection new.
		pkgNames do: [ :pkgName |
			pkgs addAll: (pkgsMatching value: pkgName)
		].
		pkgs removeDuplicates.
		runCoverage value: 'all' value: pkgs
	]
].
"
}

main() {
	copy_image
	run_coverage
}

main

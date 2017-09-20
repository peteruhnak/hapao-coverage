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
(Smalltalk hasClassNamed: #RTView)
	ifFalse: [ |packages base|
		Metacello new
			baseline: 'Geometry';
			repository: 'github://peteruhnak/geometry/repository';
			load.
		packages := #(
			'Trachel-akevalion.421.mcz'
			'Roassal2-PavelKrivanek.1693.mcz'
		).
		base := 'https://dztm7az76bgwm.cloudfront.net/roassal2'.
		packages do: [ :each | |response|
			response := ZnEasy get: base, '/', each.
			[ MczInstaller installStream: response entity readStream ] on: Notification do: [ "ignore warnings" ].
		].
		#RTAbstractInteractionView asClass subclass: #RTFindInAView.
		#RTFindInAView asClass compile: 'initializeElement: aView'.
	].
(Smalltalk hasClassNamed: #Hapao2)
	ifFalse: [ |packages base|
		packages := #(
			'Spy2-Core-AlejandroInfante.41.mcz'
			'Spy2-Visualization-AlexandreBergel.7.mcz'
			'Spy2-Hapao-Core-AlejandroInfante.16.mcz'
			'Spy2-Hapao-Visualization-AlejandroInfante.19.mcz'
		).
		base := 'https://dztm7az76bgwm.cloudfront.net/hapao'.
		packages do: [ :each | |response|
			response := ZnEasy get: base, '/', each.
			[ MczInstaller installStream: response entity readStream ] on: Notification do: [ "ignore warnings" ].
		].
	].

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
	#travis_fold start copy_image "Copying image for coverage..."
	#	timer_start
		copy_image
	#	timer_finish
	#travis_fold end copy_image
	#travis_fold start copy_image "Running hapao coverage..."
	#	timer_start
		run_coverage
	#	timer_finish
	#travis_fold end copy_image
}

main

baselines
baseline: spec
	<baseline>
	spec
		for: #common
		do: [
			spec package: 'HapaoCoverageTest'.
			spec group: 'default' with: #('HapaoCoverageTest') ]
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'			=> 'Mac::AppleEvents::Simple',
	'VERSION_FROM'		=> 'Simple.pm',
	'PREREQ_PM'	=> {
    		'Mac::Apps::Launch'  => 1.81,
    		'Mac::AppleEvents'   => 1.25,
    		'Mac::Processes'     => 1.04,
    		'Test::More'         => 0,
	},
	'clean'	=> {
		'FILES'	=> 'Mac-AppleEvents-Simple-*'
	},
);

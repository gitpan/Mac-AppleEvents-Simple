use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Mac::AppleEvents::Simple',
    'PREREQ_PM' => ['Mac::Apps::Launch' => '1.70'],
    'VERSION_FROM' => 'Simple.pm', # finds $VERSION
);

#!perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Mac::AppleEvents::Simple ':all';
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $x = $MacPerl::Version;
$x =~ s/\s+.*$//;
if (
	$x ge '5.2.0r4' && $] >= 5.004
) {
	print "ok 2\n";
} else {
	print "not ok 2: upgrade MacPerl to 5.2.0r4 or better\n";
}

open FOO, ">Dev:Console:Foo" or die $!;
select FOO;
$|++;
select STDOUT;
print FOO "ha!\n";
my $evt = build_event(qw/core clos McPL/,
  "'----':obj {form:name, want:type(cwin), seld:TEXT(\@), from:'null'()}",
  'Foo'
);
my $res = $evt->send_event(kAENoReply())->get;
printf "%sok 3%s\n", $res ? ('not ', "<$res>") : ('', '');

package Mac::AppleEvents::Simple;

use Mac::AppleEvents;
use Mac::Apps::Launch;
use vars qw(@ISA @EXPORT $VERSION);
use strict;
use Exporter;
use Carp;
@ISA = qw(Exporter);
@EXPORT = qw(do_event get_text);
$VERSION = sprintf("%d.%02d", q$Revision: 0.02 $ =~ /(\d+)\.(\d+)/);

sub new {
	my $pkg = shift or croak('Not enough parameters');
	my $self = bless _construct(@_), $pkg;
	$self->_build_event();
	$self->_print_desc('EVT');
	$self;
}

sub get_text {
	my($self, @arr) = $_[0];
	push @arr, $1 while ($self =~ /Ò([^Ó]*)Ó/g);
	return wantarray ? @arr : $arr[0];
}

sub do_event {
	my $self = bless _construct(@_), __PACKAGE__;
	$self->_build_event();
	$self->_send_event();
	$self->_print_desc('EVT');
	$self->_print_desc('REP');
	$self;
}

sub ae_send {
	my $self = shift;
	$self->_send_event(@_);
	$self->_print_desc('EVT');
	$self->_print_desc('REP');
	$self;
}

sub _construct {
	my $self = {};
	$self->{CLASS} = shift or croak('Not enough parameters');
	$self->{EVNT} = shift or croak('Not enough parameters');
	$self->{APP} = shift or croak('Not enough parameters');
	$self->{DESC} = shift || '';
	$self->{PARAMS} = [@_];
	$self;
}

sub _build_event {
	my $self = shift;
	$self->{EVT} = AEBuildAppleEvent($self->{CLASS}, $self->{EVNT},
		'sign', $self->{APP}, 0, 0, $self->{DESC}, @{$self->{PARAMS}})
		or croak $^E;
}

sub _send_event {
	my $self = shift;
	LaunchApps([$self->{APP}], 1);
	$self->{REP} = AESend($self->{EVT}, kAEWaitReply(),
		kAENormalPriority(), 60*60*9999)
		or croak $^E;
}

sub _print_desc {
	my $self = shift;
	my %what = (EVT=>'EVENT', REP=>'REPLY');
	$self->{$what{$_[0]}} = AEPrint($self->{$_[0]}) or croak $^E;
}

DESTROY {
	my $self = shift;
	AEDisposeDesc($self->{EVT}) if defined($self->{EVT});
	AEDisposeDesc($self->{REP}) if defined($self->{REP});
}

__END__

=head1 NAME

Mac::AppleEvents::Simple - MacPerl module to do Apple Events more simply

=head1 SYNOPSIS

	#!perl -w
	use Mac::AppleEvents::Simple;
	use Mac::Files;
	$alias = NewAliasMinimal(scalar MacPerl::Volumes);
	do_event(qw/aevt odoc MACS/, "'----':alis(\@\@)", $alias);

=head1 DESCRIPTION

This is just a simple way to do Apple Events.  The example above was 
previously done as:

	#!perl -w
	use Mac::AppleEvents;
	use Mac::Files;
	$alias = NewAliasMinimal(scalar MacPerl::Volumes);
	$evt = AEBuildAppleEvent(qw/aevt odoc sign MACS 0 0/,
		"'----':alis(\@\@)", $alias) or die $^E;
	$rep = AESend($evt, kAEWaitReply()) or die $^E;
	AEDisposeDesc($rep);
	AEDisposeDesc($evt);

The building, sending, and disposing is done automatically.  The function 
returns an object containing the parameters, including the C<AEPrint()> 
results of C<AEBuildAppleEvent()> C<($event-E<gt>{EVENT})> and C<AESend()>
C<($event-E<gt>{REPLY})>.

The raw AEDesc forms are in C<($event-E<gt>{EVT})> and C<($event-E<gt>{REP})>.
So if I also used the C<Mac::AppleEvents> module, I could extract the direct
object from the reply like this:

	$dobj = AEPrint(AEGetParamDesc($event->{REP}, keyDirectObject()));

So you can still mess around with the events if you need to.

=head1 FUNCTIONS

=over 4

=item [$EVENT =] do_event(CLASSID, EVENTID, APPID, FORMAT, PARAMETERS ...)

Documented above.  More documentation to come as this thing gets fleshed out
more.

=item $EVENT = Mac::AppleEvents::Simple->new(CLASSID, EVENTID, APPID, FORMAT, 
	PARAMETERS ...)

This is for delayed execution of the event.  Build it with C<new()>, and then 
send it with C<ae_send()> method.  Not sure how useful this is yet.

=item $EVENT->ae_send();

I will probably add ways to change the sending parameters (REPLY, PRIORITY, 
TIMEOUT) through this method, so if you need to send it a special way, you'll 
be able to.  You can send an event constructed with C<new()>, or re-send an 
event constructed and sent with C<do_event()>.

=item get_text(STRING);

This basically just strips out the curly quotes.  It returns the first text in 
curly quotes it finds in scalar context, and all of them in a list in list 
context.

=back

=head1 EXPORT

Exports functions C<do_event()>, C<get_text()>.

=head1 HISTORY

=over 4

=item v0.02, May 19, 1998

Here goes ...

=back

=head1 AUTHOR

Chris Nandor F<E<lt>pudge@pobox.comE<gt>>
http://pudge.net/

Copyright (c) 1998 Chris Nandor.  All rights reserved.  This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself.  Please see the Perl Artistic License.

=head1 SEE ALSO

Mac::AppleEvents, Mac::OSA, Mac::OSA::Simple, macperlcat.

=head1 VERSION

Version 0.02 (19 May 1998)

=cut

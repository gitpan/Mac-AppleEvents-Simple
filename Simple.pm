package Mac::AppleEvents::Simple;

use Mac::AppleEvents;
use Mac::Processes;
use Mac::Apps::Launch 1.60;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION $SWITCH);
use strict;
use Exporter;
use Carp;
@ISA = qw(Exporter Mac::AppleEvents);
@EXPORT = qw(do_event build_event get_text);
@EXPORT_OK = @Mac::AppleEvents::EXPORT;
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);
$VERSION = '0.52';
$SWITCH = 1;

sub do_event {
	my $self = bless _construct(@_), __PACKAGE__;
	$self->_build_event();
	$self->_send_event();
    $self->_sending();
	$self;
}

sub build_event {
	my $self = bless _construct(@_), __PACKAGE__;
	$self->_build_event();
	$self->_print_desc('EVT');
	$self;
}

sub send_event {
	my $self = shift;
	$self->_send_event(@_);
    $self->_sending();
	$self;
}

# deprecated name
*ae_send = \&send_event;

sub get_text {
	my($self, @arr) = $_[0];
	push @arr, $1 while ($self =~ /Ò([^Ó]*)Ó/g);
	return wantarray ? @arr : $arr[0];
}

sub _sending {
    my $self = shift;
	$self->_print_desc('EVT');
	$self->_print_desc('REP');
	$self->_event_error();
    $self->_warn();    
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

	# note: if $SWITCH is 0, will not switch; but we want to run this
	# if app is not already running.
	unless (IsRunning($self->{APP})) {
    	LaunchApps([$self->{APP}], $SWITCH);
    }

    if ($SWITCH) {
        while (my($k, $v) = each %Process) {
            if ($v->processSignature eq $self->{APP}) {
                SetFrontProcess($k);
            }
        }
    }

	$self->{R} = defined($_[0]) ? $_[0] : $self->{REPLY}    || kAEWaitReply();
	$self->{P} = defined($_[1]) ? $_[1] : $self->{PRIORITY} || kAENormalPriority();
	$self->{T} = defined($_[2]) ? $_[2] : $self->{TIMEOUT}  || 3600*9999;

	$self->{REP} = AESend(@{$self}{'EVT', 'R', 'P', 'T'}) or croak $^E;
}

sub _event_error {
    my($self) = @_;
    my($event, $errn, $errs, $error);
    $event = $self->{REP};
    return unless $event;

    $errn = AEGetParamDesc($event, keyErrorNumber);
    $errs = AEGetParamDesc($event, keyErrorString);
    if ($errn) {
      $error = " " . $errn->get;
      AEDisposeDesc($errn);
    }
    if ($errs) {
      $error .= sprintf(": %s", $errs->get);
      AEDisposeDesc($errs);
    }
    $self->{ERROR} = $error ? "Application error$error" : undef;
}

sub _print_desc {
	my $self = shift;
	my %what = (EVT=>'EVENT', REP=>'REPLY');
	$self->{$what{$_[0]}} = AEPrint($self->{$_[0]}) or croak $^E;
}

sub _warn {
    my $self = shift;
    my $error = $self->{ERROR};
    if ($error && $^W) {
        carp $error;
    }
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
	use Mac::Files;  # for NewAliasMinimal()
	$alias = NewAliasMinimal(scalar MacPerl::Volumes);
	do_event(qw/aevt odoc MACS/, "'----':alis(\@\@)", $alias);

	# [...]
	use Mac::AppleEvents;  # for kAENoReply()
	$evt = build_event(qw/aevt odoc MACS/, "'----':alis(\@\@)", $alias);
	$evt->send_event(kAENoReply());
	

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

The sending of the event uses as its defaults C<(kAEWaitReply(),
kAENormalPriority(), 3600*9999)>.  To use different parameters, use
C<build_event()> with C<send_event()>.

Setting C<$Mac::AppleEvents::Simple::SWITCH = 0> prevents target app from 
going to the front on C<_send_event()>.

Sending an event with C<send_event()> or C<do_event()> will check for errors
automatically, and if there is an error and the C<-w> flag is on (or C<$^W> is
nonzero), the error will be sent to C<STDERR>.  This will also only happen if
the event return an error in the standard C<errn> or C<errs> keywords.  If your
app returns errors in another way, you can roll your own warning system.  This 
example assumes the direct object in the reply is the error if it is a negative
integer:

    my $event = do_event( ... );
    my_warn_for_this_app($event);

    sub my_warn_for_this_app {
        my $event = shift;
        my $error = AEGetParamDesc($event->{REP}, keyDirectObject);
        if ($error) {
            my $err = $error->get;
            if ($err =~ /^-\d+$/ && $^W) {
                warn "Application error: $err";
            }
            AEDisposeDesc($error);
        }
    }

=head1 REQUIREMENTS

MacPerl 5.2.0r4 or better, and Mac::Apps::Launch 1.50.

=head1 FUNCTIONS

=over 4

=item [$EVENT =] do_event(CLASSID, EVENTID, APPID, FORMAT, PARAMETERS ...)

Documented above.  More documentation to come as this thing gets fleshed out
more.

=item $EVENT = build_event(CLASSID, EVENTID, APPID, FORMAT, PARAMETERS ...)

This is for delayed execution of the event, or to build an event that will be 
sent specially with C<send_event()>.  Build it with C<build_event()>, and then 
send it with C<send_event()> method.  Not sure how useful this is yet.

=item $EVENT->send_event([REPLY, PRIORITY, TIMEOUT]);

For sending events differntly than the default, which is C<(kAEWaitReply(),
kAENormalPriority(), 3600*9999)>, or re-sending an event.  The parameters 
are sticky for a given event, so:

	$evt->send_event(kAENoReply());
	$evt->send_event();  # kAENoReply() is still used


=item get_text(STRING);

This basically just strips out the curly quotes.  It returns the first text in 
curly quotes it finds in scalar context, and all of them in a list in list 
context.

=back

=head1 EXPORT

Exports functions C<do_event()>, C<build_event()>, C<get_text()>.

=head1 HISTORY

=over 4

=item v0.52, September 30, 1998

Re-upload, sigh.

=item v0.51, September 29, 1998

Fixed problems accepting parameters in C<send_event>.   Sped up
switching routine significantly.

=item v0.50, September 16, 1998

Only C<LaunchApps()> when sending event now if $SWITCH is nonzero or
app is not already running.

Added warnings for event errors if present and if C<$^W> is nonzero.
Only works if event errors use standard keywords C<errs> or C<errn>.

=item v0.10, June 2, 1998

Changed C<new()> to C<build_event()>, and C<ae_send()> to C<send_event()>.

Made default C<AESend()> parameters overridable via C<send_event()>.

=item v0.03, June 1, 1998

Added C<$SWITCH> global var to override making target app go to front.

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

=cut

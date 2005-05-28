#!/usr/bin/perl
#######################
# Audio::Play::MPG321 #
#   By Da-Breegster   #
#######################

package Audio::Play::MPG321;

use strict;
use warnings;
use IPC::Open2;
use IO::Select;
use 5.006;
our $VERSION = 0.001;

sub new {
 my $class = shift;
 my ($read, $write);
 my $pid = open2($read, $write, "mpg321", "--aggressive",
                 "--skip-printing-frames=39", "-R", "start");
 my $handle = IO::Select->new($read);
 my $self = {
  pid => $pid,
  read => $read,
  write => $write,
  handle => $handle,
  song => undef,
  sofar => "0:00",
  remains => "0:00",
  state => 0
 };
 bless($self, $class);
 return $self;
}

sub poll {
 my $self = shift;
 while ($self->{handle}->can_read(0.5)) {
  my $in;
  sysread($self->{read}, $in, 1024);
  $self->parse($in);
 }
}

sub parse {
 my $self = shift;
 my $in = shift;
 if ($in =~ m/^\@P /) {
  $in =~ s/^\@P //;
  $self->{state} = $in;
 } elsif ($in =~ m/^\@F /) {
  $in =~ s/^\@F \d+ \d+ //;
  my ($sofar, $remains) = split(/ /, $in);
  $self->{sofar} = sprintf("%d:%02d", int($sofar / 60), $sofar % 60);
  $self->{remains} = sprintf("%d:%02d", int($remains / 60), $remains % 60);
 }
}

sub play {
 my $self = shift;
 my $song = shift;
 print { $self->{write} } "load $song\n";
 $self->{state} = 2;
}

sub state {
 my $self = shift;
 return $self->{state};
}

sub toggle {
 my $self = shift;
 print { $self->{write} } "pause\n";
}

sub pause {
 my $self = shift;
 print { $self->{write} } "pause\n" if $self->state() == 2;
}

sub resume {
 my $self = shift;
 print { $self->{write} } "pause\n" if $self->state() == 1;
}

sub seek {
 print join "\n", @_;
 my $self = shift;
 my $direction = shift;
 my $position = shift;
 $position *= 39;
 print { $self->{write} } "jump $direction" . "$position\n";
}

sub stop {
 my $self = shift;
 print { $self->{write} } "quit\n";
}

1;

__END__

=head1 NAME

Audio::Play::MPG321 - A frontend to MPG321.

=head1 SYNOPSIS

  use Audio::Play::MPG321;
  my $player = new Audio::Play::MPG321;

  $SIG{CHLD} = 'IGNORE';
  $SIG{INT} = sub {
    $player->stop();
    exit 1;
  };

  $player->play("/home/dabreegster/mp3/foo.mp3");
  do {
    $player->poll();
    print $player->{sofar}, "   ", $player->{remains}, "   ", $player->state(),
    "\n";
  } until $player->state() == 0;

  $player->play("/home/dabreegster/mp3/bar.mp3");
  sleep until $player->state() == 0;

=head1 DESCRIPTION

This is a frontend to the MPG321 MP3 player. It talks to it in remote mode and
provides constant feedback about the time elapsed so far, the time remaining,
and the state of the player. If you use Audio::Play::MPG321 directly, then you
will have to do some extra work outside of the module, as demonstrated in the
synopsis. If you want to build a basic queue (Play one song, then play
another), then you must keep calling poll() to make sure Audio::Play::MPG321
knows how MPG321 is doing and testing state() to be 0.

The standard MPG321 player could be used, though some minor modifications would
have to be made to parse(). When I wrote this module, to simplify things, I
modified MPG321 to produce only certain types of output. It is recommended that
you build the module from the source included in the distribution or use a
binary provided. The modifications I made are not enhancements, nor bug fixes,
they merely made it easier for me to write this module.

=head2 METHODS

=over 4

=item new 

This method takes no additional arguments and simply starts MPG321, initialises
connections to it, and returns a player object.

=item poll

Messages from MPG321 will build up unless you call this subroutine routinely.
It's perfectly okay to leave the messages there, but if you want to build any
sort of music queue or desire any status information, you will need to call
this.

=item parse

This should never be called directly; poll() will call it for you. This just
takes a line of input from MPG321 and parses it.

=item play

This takes a single argument: The full path to a MP3 file. Like the name
suggests, it immediatly plays it.

=item state

This returns a status code: 0 if the song has ended, 1 if the song is paused,
or 2 if the song is playing. Frequent calls to poll() are necessary if this
information is to be kept current.

=item toggle

If the player is paused, this resumes it. If it's playing, it'll pause it.

=item pause

This forces a pause. Pausing while paused yields no effect.

=item resume

This forces a resume. Resuming while playing yields no effect.

=item seek

The first argument should be "+" or "-" if that direction in time is desired
for the seeking, or undef otherwise. The second argument should be the number
of seconds.

=item stop

The name may be a bit confusing, but since I see no reason to ever force a song
into state 0, this closes the player. MPG321 will exit and somewhere along the
line, a signal handler for CHLD must be defined to reap the zombie.

=back

=head1 AUTHOR

Da-Breegster <scarlino@bellsouth.net>

=cut

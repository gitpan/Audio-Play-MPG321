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
our $VERSION = 0.004;

sub new {
	my $class = shift;
	my ($read, $write);
	my $pid = open2($read, $write, "mpg321", "--aggressive",
					"--skip-printing-frames=39", "-R", "start");
					# The start parameter is needed because MPG321 requires a
					# dummy argument to be used with -R.
	my $handle = IO::Select->new($read);
	my $self = {
		pid => $pid,
		read => $read,
		write => $write,
		handle => $handle,
		sofar => "0:00",	# Time elapsed so far in current song.
		remains => "0:00",	# Time remaining for current song.
		state => 0			# 0=Stopped, 1=Paused, 2=Playing
	};
	bless($self, $class);
	return $self;
}

sub poll {
	my $self = shift;
	while ($self->{handle}->can_read(0.5)) {
		my $msg;
		sysread($self->{read}, $msg, 1024);
		foreach (split(/\n/, $msg)) {
			$self->parse($msg);
		}
	}
}

sub parse {
	my $self = shift;
	my $msg = shift;
	if ($msg =~ m/^\@P /) {							# @P means a state change.
		$msg =~ s/^\@P //;
		$self->{state} = $msg;
	} elsif ($msg =~ m/^\@F /) {					# The first two numbers are
		$msg =~ s/^\@F \d+ \d+ //;					# disregarded frame times.
		my ($sofar, $remains) = split(/ /, $msg);
		$self->{sofar} = sprintf("%d:%02d", int($sofar / 60), $sofar % 60);
		$self->{remains} = sprintf("%d:%02d", int($remains / 60), $remains %
									60);
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
	my $self = shift;
	my $direction = shift;	# Direction is either + or -.
	my $position = shift;
	$position *= 39;		# 39 MPEG frames are equivalent to about 1 second.
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

$SIG{CHLD} = 'IGNORE';	# May not work everywhere!
$SIG{INT} = sub {
	$player->stop();
	exit 0;
};

$player->play("/home/dabreegster/foo.mp3");
do {
	$player->poll();
	print $player->{sofar}, "   ", $player->{remains}, "   ",
		  $player->state(), "\n";
   } until $player->state() == 0;
	
$player->play("/home/dabreegster/bar.mp3");
sleep until $player->state() == 0;

=head1 DESCRIPTION

This is a frontend to the MPG321 MP3 player. It talks to it in remote mode and
provides constant feedback about the time elapsed so far, the time remaining,
and the state of the player. If you use Audio::Play::MPG321 directly, then you
will have to do some extra work outside of the module, as demonstrated in the
synopsis. If you want to build a basic queue (Play one song, then play
another), then you must keep calling poll() to make sure Audio::Play::MPG321
knows how MPG321 is doing and testing state() to be 0.

=head2 METHODS

=over 4

=item new

This method takes no additional arguments and simply starts MPG321, initialises
connections to it, and returns a player object.

=item poll

Messages from MPG321 will build up unless you call this subroutine routinely.
It's perfectly okay to leave the messages there, but if you want to build any
sort of music queue or desire any status information, you will need to call
this frequently.

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

Da-Breegster <dabreegster@gmail.com>

=cut

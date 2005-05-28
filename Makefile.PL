use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Audio::Play::MPG321',
    VERSION_FROM      => 'lib/Audio/Play/MPG321.pm', # finds $VERSION
    PREREQ_PM         => {IPC::Open2 => 1.01, IO::Select => 1.16},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  => "Audio::Play::MPG321",
       AUTHOR         => 'Da-Breegster <scarlino@bellsouth.net>') : ()),
);

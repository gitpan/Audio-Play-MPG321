use 5.008004;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Audio::Play::MPG321',
    VERSION_FROM      => 'lib/Audio/Play/MPG321.pm',
    PREREQ_PM         => {IPC::Open2 => 1.01, IO::Select => 1.16},
    ($] >= 5.005 ?
      (ABSTRACT  => "Audio::Play::MPG321",
       AUTHOR         => 'Da-Breegster <dabreegster@gmail.com>') : ()),
);

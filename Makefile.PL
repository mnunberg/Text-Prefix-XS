use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Prefix::XS',
    AUTHOR              => q{M. Nunberg <mnunberg@haskaah.org>},
    VERSION_FROM        => 'lib/Text/Prefix/XS.pm',
    ABSTRACT_FROM       => 'lib/Text/Prefix/XS.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Digest::SHA1' => 1,
        'XSLoader'  => 0,
        'Test::Deep'=> 0.108
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Prefix-XS-*' },
);

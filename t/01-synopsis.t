#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Text::Prefix::XS;
my @haystacks = qw(
    garbage
    blarrgh
    FOO
    meh
    AA-ggrr
    AB-hi!
);

my @needles = qw(AAA AB FOO FOO-BAR);

my $search = prefix_search_create( map uc($_), @needles );

my %seen_hash;

foreach my $haystack (@haystacks) {
    if(my $prefix = prefix_search($search, $haystack)) {
        $seen_hash{$prefix}++;
    }
}

ok($seen_hash{'FOO'} == 1, 'XS Example');

#Compare to:
my $re = join('|', map quotemeta $_, @needles);
$re = qr/^($re)/;
%seen_hash = ();
foreach my $haystack (@haystacks) {
    my ($match) = ($haystack =~ $re);
    if($match) {
        $seen_hash{$match}++;
    }
}
ok($seen_hash{'FOO'} == 1, 'RE Example');
done_testing();

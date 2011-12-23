package Text::Prefix::XS;
use XSLoader;
use strict;
use warnings;

our $VERSION = '0.09';

XSLoader::load __PACKAGE__, $VERSION;
use base qw(Exporter);
our @EXPORT = qw(
    prefix_search_build
    prefix_search_create
    prefix_search
    prefix_search_multi);
1;

sub prefix_search_create(@)
{
    my @copy = @_;
    @copy = sort { length $b <=> length $a || $a cmp $b } @copy;
    return prefix_search_build(\@copy);
}

__END__

=head1 NAME

Text::Prefix::XS - Fast prefix searching

=head1 SYNOPSIS

    use Text::Prefix::XS;
    my @haystacks = qw(
        garbage
        blarrgh
        FOO
        meh
        AA-ggrr
        AB-hi!
    );
    
    my @prefixes = qw(AAA AB FOO FOO-BAR);
    
    my $search = prefix_search_create( map uc($_), @prefixes );
    
    my %seen_hash;
    
    foreach my $haystack (@haystacks) {
        if(my $prefix = prefix_search($search, $haystack)) {
            $seen_hash{$prefix}++;
        }
    }
    
    $seen_hash{'FOO'} == 1;
    
    #Compare to:
    my $re = join('|', map quotemeta $_, @prefixes);
    $re = qr/^($re)/;
    
    foreach my $haystack (@haystacks) {
        my ($match) = ($haystack =~ $re);
        if($match) {
            $seen_hash{$match}++;
        }
    }
    $seen_hash{'FOO'} == 1;

=head1 DESCRIPTION

This module implements something of an I<trie> algorithm for matching
(and extracting) prefixes from text strings.

A common application I had was to pre-filter lots and lots of text for a small
amount of preset prefixes.

Interestingly enough, the quickest solution until I wrote this module was to use
a large regular expression (as in the synopsis)

=head1 FUNCTIONS

The interface is relatively simple. This is alpha software and the API is subject
to change

=head2 prefix_search_create(@prefixes)

Create an opaque prefix search handle. It returns a thingy, which you should
keep around.

Internally it will order the elements in the list, with the longest prefix
being first.

It will then construct a search trie using a variety of caching and lookup layers.

=head2 prefix_search($thingy, $haystack)

Will check C<$haystack> for any of the prefixes in C<@prefixes> passed to
L</prefix_search_create>. If C<$haystack> has a prefix, it will be returned by
this function; otherwise, the return value is C<undef>

=head2 prefix_search_multi($thingy, @haystacks)

B<EXTREMELY FAST!!!>

Will check each item in C<@haystacks> for any of the C<@prefixes> passed to
L</prefix_search_create>. The return value is a hash reference. Its keys are matched
prefix strings, and its values are array references containing items from C<@haystacks>
which matched.

This function is extremely fast. It's four times quicker than the normal
L</prefix_search> function (which is itself about twice as fast as any other
method).

However, it will not gain a lot of performance benefit with optimistic searching
(meaning that a match has a good chance of being found), and will just consume
more memory (since it needs to store the results in a hash).



=head1 PERFORMANCE

In most normal use cases, C<Text::Prefix::XS> will outperform any other module
or search algorithm.

Specifically, this module is intended for a pessimistic search mechanism,
where most of the input is assumed not to match (which is usually the case anyway).

The ideal position of C<Text::Prefix::XS> would reside between raw but delimited
user input, and more complex searching and processing algorithms. This module
acts as a layer between those.

In addition to a trie, this module also uses a very fast sparse array to check
characters in the input against an index of known characters at the given
position. This is much quicker than a hash lookup.

See the C<trie.pl> script included with this distribution for detailed benchmark
comparison methods

Here are a bunch of numbers. The entries are in the format of

    [capture (Y/N)] NAME DURATION MATCHES
    
Where C<capture> means whether the test was also able to return the prefix which
matched. C<MATCHES> is the amount of matches returned.

Additionally, each test has a few parameters defining the input. These are:

=over

=item C<TERMS>

The amount of search terms

=item C<TERM_MIN>

The minimum length of a term

=item C<TERM_MAX>

The maximum length of a term

=item INPUT

The count of input strings which will be checked to see if they are prefixed with
any of the C<TERMS>. The strings are each exactly one character longer than
C<TERM_MAX>

=back

Sample input is taken by making a C<sha1_hex> string of each number from 0
until C<TERMS>, and then encoding that output into Base64, ensuring that
both the terms and the input get a diversity of the ASCII charset.


A few methods were benchmarked, and are listed as keys:

=over

=item C<Perl-Trie>

A generic implementation of a search trie in pure perl

=item C<TMFA>

L<Text::Match::FastAlternatives> C<match_at> function

=item C<perl-re>

Generic perl regex. The capturing version is C<qr/^(term1|term2)/>,
and the non-capturing version is C<qr/^(?:term1|term2)/>, where the terms
are joined together in a C<list2re> fashion.

=item C<RE2>

Same as C<perl-re>, except using L<re::engine::RE2>

=item C<TXS>

This module.

=back


    Generated INPUT=2000000 TERMS=20 TERM_MIN=3 TERM_MAX=6
    CAP   NAME       DUR	MATCH
    [Y] Perl-Trie  	2.42s	M=34768
    [N] TMFA       	1.11s	M=34768
    [N] perl-re    	1.27s	M=34768
    [N] RE2        	0.96s	M=34768
    [Y] perl-re    	1.45s	M=34768
    [Y] RE2        	2.95s	M=34768
    [Y] TXS        	0.53s	M=34768
    
    Generated INPUT=2000000 TERMS=50 TERM_MIN=10 TERM_MAX=16
    CAP   NAME       DUR	MATCH
    [Y] Perl-Trie  	2.32s	M=50
    [N] TMFA       	1.07s	M=50
    [N] perl-re    	1.27s	M=50
    [N] RE2        	0.93s	M=50
    [Y] perl-re    	1.47s	M=50
    [Y] RE2        	1.14s	M=50
    [Y] TXS        	0.55s	M=50
    
    Generated INPUT=2000000 TERMS=49 TERM_MIN=2 TERM_MAX=16
    CAP   NAME       DUR	MATCH
    [Y] Perl-Trie  	17.70s	M=420699
    [N] TMFA       	1.10s	M=420699
    [N] perl-re    	1.35s	M=420699
    [N] RE2        	0.97s	M=420699
    [Y] perl-re    	1.70s	M=420699
    [Y] RE2        	4.98s	M=420699
    [Y] TXS        	1.62s	M=420699


    Generated INPUT=2000000 TERMS=10 TERM_MIN=5 TERM_MAX=10
    CAP   NAME       DUR	MATCH
    [Y] Perl-Trie  	1.99s	M=265
    [N] TMFA       	1.07s	M=265
    [N] perl-re    	1.20s	M=265
    [N] RE2        	0.90s	M=265
    [Y] perl-re    	1.43s	M=265
    [Y] RE2        	2.70s	M=265
    [Y] TXS        	0.45s	M=265

    Generated INPUT=2000000 TERMS=100 TERM_MIN=3 TERM_MAX=25
    CAP   NAME       DUR	MATCH
    [Y] Perl-Trie  	10.35s	M=22269
    [N] TMFA       	1.15s	M=22269
    [N] perl-re    	1.40s	M=22269
    [N] RE2        	1.06s	M=22269
    [Y] perl-re    	1.58s	M=22269
    [Y] RE2        	2.06s	M=22269
    [Y] TXS        	1.10s	M=22269
    
    Generated INPUT=2000000 TERMS=200 TERM_MIN=5 TERM_MAX=25
    CAP   NAME       DUR	MATCH
    [Y] Perl-Trie  	3.81s	M=1325
    [N] TMFA       	1.16s	M=1325
    [N] perl-re    	1.30s	M=1325
    [N] RE2        	1.07s	M=1325
    [Y] perl-re    	1.56s	M=1325
    [Y] RE2        	1.38s	M=1325
    [Y] TXS        	0.63s	M=1325

    Generated INPUT=2000000 TERMS=8 TERM_MIN=2 TERM_MAX=5
    CAP   NAME       DUR	MATCH
    [Y] Perl-Trie  	1.79s	M=22168
    [N] TMFA       	1.15s	M=22168
    [N] perl-re    	1.26s	M=22168
    [N] RE2        	1.01s	M=22168
    [Y] perl-re    	1.56s	M=22168
    [Y] RE2        	2.48s	M=22168
    [Y] TXS        	0.49s	M=22168

    
I've mainly tested this on Debian's 5.10 - for newer perls, this module performs
better, and for el5 5.8, The differences are a bit lower. TBC


=head1 SEE ALSO 

There are quite a few modules out there which aim for a Trie-like search, but
they are all either not written in C, or would not be performant enough for this
application.

These two modules are implemented in pure perl, and are not part of the comparison.

L<Text::Trie>

L<Regexp::Trie>

L<Regexp::Optimizer>

L<Text::Match::FastAlternatives>

L<re::engine::RE2>


=head1 CAVEATS

I have yet to figure out a way to test this properly with threads. Currently
the trie data structure is stored as a private perl C<HV>, and I'm not sure
what happens when it's cloned across threads.

This algorithm performs quite poorly when matches are more likely. B<HOWEVER>,
in the case where there is a desire to extract the matched prefix, the overhead
in doing so with Regular Expressions outweighs the performance hit of
C<Text::Prefix::XS>, making C<Text::Prefix::XS> still effectively faster.

Search prefixes and search input is currently restricted to printable ASCII
characters

Search terms may not exceed 256 characters. You can increase this limit
(at the cost of more memory) by changing the C<#define> of
C<CHARTABLE_MAX> in the XS code and recompiling.

=head1 AUTHOR AND COPYRIGHT

Copyright (C) 2011 M. Nunberg

You may use and distribute this software under the same terms, conditions, and
licensing as Perl itself.


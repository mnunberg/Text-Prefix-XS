package Text::Prefix::XS;
use XSLoader;
use strict;
use warnings;

our $VERSION = '0.02-TRIAL';

XSLoader::load __PACKAGE__, $VERSION;
use base qw(Exporter);
our @EXPORT = qw(
    prefix_search_build
    prefix_search_create
    prefix_search);
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
    
    my @needles = qw(AAA AB FOO FOO-BAR);
    
    my $search = prefix_search_create( map uc($_), @needles );
    
    my %seen_hash;
    
    foreach my $haystack (@haystacks) {
        if(my $prefix = prefix_search($search, $haystack)) {
            $seen_hash{$prefix}++;
        }
    }
    
    $seen_hash{'FOO'} == 1;
    
    #Compare to:
    my $re = join('|', map quotemeta $_, @needles);
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

Will check C<$haystack> for any of the prefixes in C<@needles> passed to
L</prefix_search_create>. If C<$haystack> has a prefix, it will be returned by
this function; otherwise, the return value is C<undef>

=head1 PERFORMANCE

This module performs better than regex under any circumstance. In the future, a
benchmark table will be posted - but on average, it's about 30-50% quicker than
a regex.

This module would be even quicker if there were some way to implement this as an
actual C<OP> rather than an C<xsub> call. But the performance is quite nice anyway

=head1 SEE ALSO

There are quite a few modules out there which aim for a Trie-like search, but
they are all either not written in C, or would not be performant enough for this
application.

L<Text::Trie>

L<Regexp::Trie>

L<Regexp::Optimizer>

=head1 NOTES / TODO

While my implementation is probably sloppy, the simplicity of the search itself
makes it very quick and cruftless. When doing a prefix search on a large amount
of text, but with a small number of prefixes, the reduction of overhead is the
most important optimization for gaining performance.

=head1 CAVEATS

Private perl data structures are allocated internally, therefore it wouldn't do
good to use this module across threads. Also, memory leaks will ensue if you
destroy the search object. But, search handles are expensive to create, and are
assumed to be made for relatively static 'needles'.

This is only because the developer is lazy and tired. Most of this should be
fixed in a stable release

=head1 AUTHOR AND COPYRIGHT

Copyright (C) 2011 M. Nunberg

You may use and distribute this software under the same terms, conditions, and
licensing as Perl itself.


#!perl
package autobox::Closure::Attributes;
use strict;
use warnings;
use parent 'autobox';

sub import {
    shift->SUPER::import(CODE => 'autobox::Closure::Attributes::Methods');
}

package autobox::Closure::Attributes::Methods;
use PadWalker;

sub AUTOLOAD {
    my $code = shift;
    (my $attr = our $AUTOLOAD) =~ s/.*:://;

    $attr = "\$$attr"; # this will become smarter soon

    my $closed_over = PadWalker::closed_over($code);
    exists $closed_over->{$attr}
        or Carp::croak "$code does not close over $attr";

    return ${ $closed_over->{$attr} } = shift if @_;
    return ${ $closed_over->{$attr} };
}


=head1 NAME

autobox::Closure::Attributes - closures are objects are closures

=head1 VERSION

Version 0.02 released 21 Feb 08

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use autobox::Closure::Attributes;

    sub accgen {
        my $n = shift;
        return sub { $n += shift || 1 }
    }

    my $from_3 = accgen(3);

    $from_3->n     # 3
    $from_3->()    # 4
    $from_3->n     # 4
    $from_3->n(10) # 10
    $from_3->()    # 11
    $from_3->m     # "CODE(0xDEADBEEF) does not close over $m"

=head1 WHAT?

The venerable master Qc Na was walking with his student, Anton. Hoping to
prompt the master into a discussion, Anton said "Master, I have heard that
objects are a very good thing - is this true?" Qc Na looked pityingly at his
student and replied, "Foolish pupil -- objects are merely a poor man's
closures."

Chastised, Anton took his leave from his master and returned to his cell,
intent on studying closures. He carefully read the entire "Lambda: The
Ultimate..." series of papers and its cousins, and implemented a small Scheme
interpreter with a closure-based object system. He learned much, and looked
forward to informing his master of his progress.

On his next walk with Qc Na, Anton attempted to impress his master by saying
"Master, I have diligently studied the matter, and now understand that objects
are truly a poor man's closures." Qc Na responded by hitting Anton with his
stick, saying "When will you learn? Closures are a poor man's objects." At that
moment, Anton became enlightened.

=head1 DESCRIPTION

This module uses powerful tools to give your closures accessors for each of the
closed-over variables. You can get I<and> set them.

For now, you can get I<only> the scalars that are closed over. Once I think of
a better interface for getting and setting arrays and hashes I'll add that.
C<< $code->'@foo' >> is the easy part.

=head1 HOW DOES IT WORK?

Go ahead and read the source code of this, it's not very long.

L<autobox> lets you call methods on coderefs (or any other scalar).

L<PadWalker> will let you see and change the closed-over variables of a coderef .

C<AUTOLOAD> is really just an accessor. It's just harder to manipulate the
"attributes" of a closure-based object than it is for hash-based objects.

=head1 WHY WOULD YOU DO THIS?

    <#moose:jrockway> that reminds me of another thing that might be insteresting:
    <#moose:jrockway> sub foo { my $hello = 123; sub { $hello = $_[0] } }; my $closure = foo(); $closure->hello # 123
    <#moose:jrockway> basically adding accessors to closures
    <#moose:jrockway> very "closures are just classes" or "classes are just closures"

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail.com> >>

=head1 SEE ALSO

L<autobox>, L<PadWalker>

The L</WHAT?> section is from Anton van Straaten: L<http://people.csail.mit.edu/gregs/ll1-discuss-archive-html/msg03277.html>

=head1 BUGS

    my $code = do {
        my ($x, $y);
        sub { $y }
    };
    $code->y # ok
    $code->x # CODE(0xDEADBEEF) does not close over $x

This happens because Perl optimizes away the capturing of unused variables.

    my $code = do {
        my @primes = qw(2 3 5 7);
        sub { $primes[ $_[0] ] }
    };

    $code->'@primes'(1) # Perl complains

    my $method = '@primes';
    $code->$method(1) # autobox complains

    $code->can('@primes')->($code, 1) # can complains

    $code->ARRAY_primes(1) # Sartak complains

    $code->autobox::Closure::Attributes::Array::primes(1) # user complains

I just can't win here. Ideas?

Please report any other bugs through RT: email
C<bug-autobox-closure-attributes at rt.cpan.org>, or browse
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=autobox-Closure-Attributes>.

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;


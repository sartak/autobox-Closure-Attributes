package autobox::Closure::Attributes;
use strict;
use warnings;
use base 'autobox';
use B;
use Want;
our $VERSION = '0.05_1';

our @leaves;

sub import {
    shift->SUPER::import(CODE => 'autobox::Closure::Attributes::Methods');
    push @leaves, $^H{autobox_leave}; # keep them forever so their destructor never gets invoked?
}

package autobox::Closure::Attributes::Methods;
use PadWalker;

sub AUTOLOAD :lvalue {
    my $code = shift;
    (my $method = our $AUTOLOAD) =~ s/.*:://;
    return if $method eq 'DESTROY';

    # we want the scalar unless the method name already a sigil
    my $attr = $method  =~ /^[\$\@\%\&\*]/ ? $method : '$' . $method;

    my $closed_over = PadWalker::closed_over($code);

    # is there a method of that name in the package the coderef was created in?
    # if so, run it.
    # give methods priority over the variables we close over.
    # XXX this isn't lvalue friendly, but sdw can't figure out how to make it be and not piss off old perls.

    my $stash = B::svref_2object($code)->STASH->NAME;
    if( $stash and $stash->can($method) ) {
        return $stash->can($method)->( $code, @_ );
    }

    exists $closed_over->{$attr} or Carp::croak "$code does not close over $attr";

    my $ref = ref $closed_over->{$attr};

    if (@_) {
        return @{ $closed_over->{$attr} } = @_ if $ref eq 'ARRAY';
        return %{ $closed_over->{$attr} } = @_ if $ref eq 'HASH';
        return ${ $closed_over->{$attr} } = shift;
    }

    $ref eq 'HASH' || $ref eq 'ARRAY' ? $closed_over->{$attr} : ${ $closed_over->{$attr} };  # lvalue friendly return

}

1;

__END__

=head1 NAME

autobox::Closure::Attributes - closures are objects are closures

=head1 VERSION

Version 0.03 released 16 May 08

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

You can also call invoke methods defined in the package the coderef was created in:
    
    {
        package Foo;
        sub new {
            my $package = shift;
            my $x = shift;
            sub {
                $x *= 2;
            };
        }
        sub inc_x { my $self = shift; ++ $self->x }
    };
    
    my $foo = Foo->new(10);
    $foo->inc_x;     # $x is now 11; calls the method inc_x
    $foo->x = 15;    #           15; assigns to $x
    $foo->x(20);     #           20; assigns to $x
    $foo->();        #           40; runs the sub { }
    $foo->m;         # "CODE(0xDEADBEEF) does not close over $m"

Note that the coderef returned by C<sub { }> was never C<bless>ed.

If C<Foo> is used from a different file with C<use>, then you'll need this boilerplate
in your C<Foo.pm>:

        sub import {
            my $class = shift;
            $class->autobox::import(CODE => 'autobox::Closure::Attributes::Methods');
        }

That enables autoboxing of code references in the program that uses the C<Foo.pm> module.

You can get and set arrays and hashes too, though it's a little more annoying:

    my $code = do {
        my ($scalar, @array, %hash);
        sub { return ($scalar, @array, %hash) }
    };

    $code->scalar # works as normal

    my $array_method = '@array';
    $code->$array_method(1, 2, 3); # set @array to (1, 2, 3)
    $code->$array_method; # [1, 2, 3]

    my $hash_method = '%hash';
    $code->$hash_method(foo => 1, bar => 2); # set %hash to (foo => 1, bar => 2)
    $code->$hash_method; # { foo => 1, bar => 2 }

If you're feeling particularly obtuse, you could do these more concisely:

    $code->${\ '%hash' }(foo => 1, bar => 2);
    $code->${\ '@array' }

I recommend instead keeping your hashes and arrays in scalar variables if
possible.

The effect of L<autobox> is lexical, so you can localize the nastiness to a
particular section of code -- these mysterious closu-jects will revert to their
inert state after L<autobox>'s scope ends.

=head1 HOW DOES IT WORK?

Go ahead and read the source code of this, it's not very long.

L<autobox> lets you call methods on coderefs (or any other scalar).

L<PadWalker> will let you see and change the closed-over variables of a coderef
.

L<AUTOLOAD|perlsub/"Autoloading"> is really just an accessor. It's just harder
to manipulate the "attributes" of a closure-based object than it is for
hash-based objects.

=head1 WHY WOULD YOU DO THIS?

    <#moose:jrockway> that reminds me of another thing that might be insteresting:
    <#moose:jrockway> sub foo { my $hello = 123; sub { $hello = $_[0] } }; my $closure = foo(); $closure->hello # 123
    <#moose:jrockway> basically adding accessors to closures
    <#moose:jrockway> very "closures are just classes" or "classes are just closures"

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

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

Perl 5.8.9, 5.10.0, 5.12.0, and other earlier versions fail on the package method examples with the error:
Can't modify non-lvalue subroutine call at /home/knoppix/lib/perl5/site_perl/5.8.9/autobox/Closure/Attributes.pm line 37.
Change the mutators to instead read:

    sub inc_x :lvalue { ++ $_[0]->x; $_[0]->x }
    sub inc_y :lvalue { ++ $_[0]->y; $_[0]->y }

5.14 onward are smart enough to know that those accessors aren't actually called in lvalue context even though they're called from an lvalue method (C<AUTOLOAD>).

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 Shawn M Moore.

Copyright 2013 Scott Walters (scrottie).

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


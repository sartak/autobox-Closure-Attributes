#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;
use autobox::Closure::Attributes;

{
    package Foo;
    sub new {
        my $x = 10;
        my $y = 100;
        my $inc_x_2 = sub { ++ $x };
        sub {
            $inc_x_2->() if @_;
            $x + $y;
        };
    }
    # sub inc_x { ++ $_[0]->x }  # this version of these work fine on perl 5.16
    # sub inc_y { ++ $_[0]->y }
    sub inc_x :lvalue { ++ $_[0]->x; $_[0]->x }
    sub inc_y :lvalue { ++ $_[0]->y; $_[0]->y }
};

ok( my $foo = Foo->new );
is($foo->x, 10);
is($foo->y, 100);
is($foo->inc_x, 11);
is($foo->inc_y, 101);
is($foo->inc_x, 12);
is($foo->inc_y, 102);
is($foo->(), 114);
is($foo->inc_x_2->(), 13);


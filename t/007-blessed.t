#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;
use autobox::Closure::Attributes;

{
    package Foo;
    use base 'autobox::Closure::Attributes::Methods';
    sub new {
        my $x = 10;
        my $y = 100;
        bless sub {
            $x + $y;
        }, 'Foo';
    }
    sub inc_x { ++ $_[0]->x }
    sub inc_y { ++ $_[0]->y }
};

ok( my $foo = Foo->new );
is($foo->x, 10);
is($foo->y, 100);
is($foo->inc_x, 11);
is($foo->inc_y, 101);
is($foo->(), 112);


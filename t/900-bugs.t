#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;
use autobox::Closure::Attributes;

my $code = do {
    my ($x, $y) = (10, 20);
    sub { $y }
};

is($code->y, 20);
TODO:
{
    local $TODO = "Perl (5.8 anyway) does not capture unused variables";
    throws_ok { $code->x } qr/CODE\(0x[0-9a-fA-F]+\) does not close over \$x at/
}


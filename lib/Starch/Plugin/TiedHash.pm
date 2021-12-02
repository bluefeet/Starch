package Starch::Plugin::TiedHash;
our $VERSION = '0.14';

use Moo;
use strictures 2;
use namespace::clean;

with 'Starch::Plugin::Bundle';

sub bundled_plugins {
    return [qw(
        ::TiedHash::Manager
        ::TiedHash::State
    )];
}

1;

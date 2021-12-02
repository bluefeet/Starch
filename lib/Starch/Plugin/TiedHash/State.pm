package Starch::Plugin::TiedHash::State;
our $VERSION = '0.14';

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'Starch::Plugin::ForState';

around _build_data => sub{
    my $orig = shift;
    my $self = shift;
    my %data = $self->$orig( @_ )->%*;
    tie %data, $self->manager->tied_hash_class;
    return \%data;
};

around _set_data => sub{
    my $orig = shift;
    my $self = shift;
    my %data = shift->%*;
    tie %data, $self->manager->tied_hash_class;
    return $self->$orig( \%data );
};

1;

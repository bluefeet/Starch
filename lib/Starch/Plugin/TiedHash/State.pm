package Starch::Plugin::TiedHash::State;
our $VERSION = '0.14';

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'Starch::Plugin::ForState';

around _build_data => sub{
    my $orig = shift;
    my $self = shift;
    my %data;
    tie %data, $self->manager->tied_hash_class;
    %data = %{ $self->$orig( @_ ) };
    return \%data;
};

around _set_data => sub{
    my $orig = shift;
    my $self = shift;
    my %data;
    tie %data, $self->manager->tied_hash_class;
    %data = %{ shift() };
    return $self->$orig( \%data );
};

1;

package Starch::Plugin::AutoSave;

=head1 NAME

Starch::Plugin::AutoSave - Automatically save changed session data.

=head1 SYNOPSIS

    my $starch = Starch->new_with_plugins(
        ['::AutoSave'],
        ...,
    );

=head2 DESCRIPTION

This plugin detects when a session object is being destroyed and is
dirty (the session data has changed).  If this happens the save will
be called on the session.

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Plugin::ForSession
);

sub DEMOLISH {
    my ($self) = @_;

    $self->save(); # which calls is_dirty

    return;
}

1;

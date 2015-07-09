package Web::Starch::Plugin::LogUnsaved;

=head1 NAME

Web::Starch::Plugin::LogUnsaved - Complain when session data is lost.

=head1 SYNOPSIS

    my $starch = Web::Starch->new_with_plugins(
        ['::LogUnsaved'],
        ...,
    );

=head2 DESCRIPTION

This plugin detects when a session object is being destroyed and is
dirty (the session data has changed).  If this happens an error log
message will be written.

=cut

use Carp qw( croak );

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::ForSession
);

sub DEMOLISH {
    my ($self) = @_;

    if ($self->is_dirty()) {
        $self->log->errorf(
            'Starch session %s was changed and not saved.',
            $self->id(),
        );
    }

    return;
}

1;

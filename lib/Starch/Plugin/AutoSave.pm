package Starch::Plugin::AutoSave;

=head1 NAME

Starch::Plugin::AutoSave - Automatically save changed state data.

=head1 SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::AutoSave'],
        ...,
    );

=head2 DESCRIPTION

This plugin detects when a state object is being destroyed and is
dirty (the state data has changed).  If this happens then save will
be called on the state.

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Plugin::ForState
);

sub DEMOLISH {
    my ($self) = @_;

    $self->save(); # which calls is_dirty

    return;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut


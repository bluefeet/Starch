package Starch::Plugin::LogUnsaved;

=head1 NAME

Starch::Plugin::LogUnsaved - Complain when state data is lost.

=head1 SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::LogUnsaved'],
        ...,
    );

=head2 DESCRIPTION

This plugin detects when a state object is being destroyed and is
dirty (the state data has changed).  If this happens an error log
message will be written.

=cut

use Carp qw( croak );

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Plugin::ForState
);

sub DEMOLISH {
    my ($self) = @_;

    if ($self->is_dirty()) {
        $self->log->errorf(
            'Starch state %s was changed and not saved.',
            $self->id(),
        );
    }

    return;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut


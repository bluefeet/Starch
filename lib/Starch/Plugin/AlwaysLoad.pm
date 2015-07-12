package Starch::Plugin::AlwaysLoad;

=head1 NAME

Starch::Plugin::AlwaysLoad - Always retrieve session data.

=head1 SYNOPSIS

    my $starch = Starch->new_with_plugins(
        ['::AlwaysLoad'],
        ...,
    );

=head1 DESCRIPTION

This plugin causes L<Starch::Session/data> to be always loaded
from the store as soon as the session object is created.  By default
the session data is only retrieved from the store when it is first
accessed.

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Plugin::ForSession
);

sub BUILD {
    my ($self) = @_;

    $self->data();

    return;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.


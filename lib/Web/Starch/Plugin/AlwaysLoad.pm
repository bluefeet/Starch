package Web::Starch::Plugin::AlwaysLoad;

=head1 NAME

Web::Starch::Plugin::AlwaysLoad - Always retrieve session data.

=head1 SYNOPSIS

    my $starch = Web::Starch->new_with_plugins(
        ['::AlwaysLoad'],
        ...,
    );

=head1 DESCRIPTION

This plugin causes L<Web::Starch::Session/data> to be always loaded
from the store as soon as the session object is created.  By default
the session data is only retrieved from the store when it is first
accessed.

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::ForSession
);

sub BUILD {
    my ($self) = @_;

    $self->data();

    return;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Web::Starch/AUTHOR>, L<Web::Starch/CONTRIBUTORS>, and L<Web::Starch/LICENSE>.


package Web::Starch::Component;

=head1 NAME

Web::Starch::Component - Shared role for all Web::Starch components.

=head1 DESCRIPTION

This role provides some common functionality that the manager
(L<Web::Starch>), session (L<Web::Starch::Session>), store
(L<Web::Starch::Store>), and factory (L<Web::Starch::Factory>)
share.

=cut

use Types::Standard -types;
use Log::Any;

use Moo::Role;
use strictures 2;
use namespace::clean;

=head1 ATTRIBUTES

=head2 log

A L<Log::Any::Proxy> object with the category set to the
object's blessed class minus the C<__WITH__.*> bits which
plugins add to the package name.

=cut

has log => (
    is       => 'lazy',
    isa      => InstanceOf[ 'Log::Any::Proxy' ],
    init_arg => undef,
);
sub _build_log {
    my ($self) = @_;

    my $category = ref( $self );
    $category =~ s{__WITH__.*$}{};

    return Log::Any->get_logger(category => $category);
}

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.


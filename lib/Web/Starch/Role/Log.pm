package Web::Starch::Role::Log;

=head1 NAME

Web::Starch::Role::Log - Logging capabilities used internally by Starch.

=cut

use Types::Standard -types;
use Log::Any;

use Moo::Role;
use strictures 2;
use namespace::clean;

=head1 ATTRIBUTES

=head2 log

Returns a L<Log::Any::Proxy> object used for logging to L<Log::Any>.
The category is set to the object's package name, minus any
C<__WITH__.*> bits that Moo::Role adds when composing a class
from roles.

Very little logging is produced by the stock L<Web::Starch>.  The
L<Web::Starch::Plugin::Trace> plugin logs extensively.

More info about logging can be found at
L<Web::Starch::Manual/LOGGING>.

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

package Web::Starch::Plugin::RenewExpiration::Manager;

=head1 NAME

Web::Starch::Plugin::RenewExpiration::Manager - Add arguments to the Web::Starch
object for renewing session expirations.

=head1 DESCRIPTION

This role adds methods to L<Web::Starch>.

See L<Web::Starch::Plugin::RenewExpiration> for examples of using this
module.

=cut

use Types::Standard -types;
use Types::Common::String -types;
use Types::Common::Numeric -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::ForManager
);

=head1 OPTIONAL ARGUMENTS

=head2 renew_threshold

How long to wait, since the last session write, before forcing a new
write in order to extend the sessions expiration in the sore.

Defaults to zero which will renew the session expiration on every request.

=cut

has renew_threshold => (
    is      => 'lazy',
    isa     => PositiveOrZeroInt,
    default => 0,
);

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.


package Starch::Plugin::RenewExpiration;

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Plugin::Bundle
);

sub bundled_plugins {
    return [qw(
        ::RenewExpiration::Manager
        ::RenewExpiration::State
    )];
}

1;
__END__

=head1 NAME

Starch::Plugin::RenewExpiration - Trigger periodic writes to the store.

=head1 SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::RenewExpiration'],
        renew_threshold => 10 * 60, # 10 minutes
        ...,
    );

=head1 DESCRIPTION

If your state is used for reading more than writing you may find that your
states expire in the store when they are still being used since your code
has not triggered a write of the state data by changing it.

This plugin triggers a write of the state data whether or not it has
changed.  Typically you'll want to set the L</renew_threshold> argument
so that this write only happens after the state has gotten a little stale
rather than on every time it is used.

=head1 OPTIONAL MANAGER ARGUMENTS

These arguments are added to the L<Starch::Manager> class.

=head2 renew_threshold

How long to wait, since the last state write, before forcing a new
write in order to extend the state's expiration in the store.

Defaults to zero which will renew the expiration on every request.

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut


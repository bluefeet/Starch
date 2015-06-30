package Web::Starch::Plugin::RenewExpiration;

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::Bundle
);

sub bundled_plugins {
    return [qw(
        ::RenewExpiration::Manager
        ::RenewExpiration::Session
    )];
}

1;
__END__

=head1 NAME

Web::Starch::Plugin::RenewExpiration - Trigger prediodic writes to the
session store.

=head1 SYNOPSIS

    my $starch = Web::Starch->new_with_plugins(
        ['::RenewExpiration'],
        renew_threshold => 10 * 60, # 10 minutes
        ...,
    );

=head1 DESCRIPTION

If your session is used for reading more than writing you may find that your
sessions expire in the store when they are still being used since your code
has not triggered a write of the session data.

This plugin triggers a write of the session data whether or not it has
changed.  Typically you'll want to set the L</renew_threshold> argument
so that this write only happens after the session has gotten a little stale
rather than on every request.

=head1 OPTIONAL MANAGER ARGUMENTS

These areguments are added to the L<Web::Starch> class.

=head2 renew_threshold

How long to wait, since the last session write, before forcing a new
write in order to extend the sessions expiration in the store.

Defaults to zero which will renew the session expiration on every request.

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.


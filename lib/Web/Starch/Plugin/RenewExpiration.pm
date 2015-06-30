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

This plugin provides two roles;
L<Web::Starch::Plugin::RenewExpiration::Session>
which adds methods to the session object, and
L<Web::Starch::Plugin::RenewExpiration::Manager>
which adds arguments to the Starch object.

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.


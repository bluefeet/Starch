package Web::Starch::Plugin::CookieArgs;

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::Bundle
);

sub bundled_plugins {
    return [qw(
        ::CookieArgs::Manager
        ::CookieArgs::Session
    )];
}

1;
__END__

=head1 NAME

Web::Starch::Plugin::CookieArgs - Arguments and methods for dealing with
HTTP cookies.

=head1 SYNOPSIS

    my $starch = Web::Starch->new_with_plugins(
        ['::CookieArgs'],
        cookie_name => 'my_session',
        store => { ... },
    );
    my $session = $starch->session();
    my $cookie_args = $session->cookie_args();
    print $cookie_args->{name}; # my_session

=head1 DESCRIPTION

This plugin provides two roles L<Web::Starch::Plugin::CookieArgs::Session>,
which adds methods to the session object, and
L<Web::Starch::Plugin::CookieArgs::Manager> which adds arguments to the
Starch object.

This plugin is meant to ease the work of integrating Starch with various
web frameworks.

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.


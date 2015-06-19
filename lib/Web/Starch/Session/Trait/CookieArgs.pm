package Web::Starch::Session::Trait::CookieArgs;

=head1 NAME

Web::Starch::Session::Trait::CookieArgs - Add arguments and methods to sessions
for dealing with HTTP cookies.

=head1 SYNOPSIS

    my $starch = Web::Starch->new(
        ...,
        session_traits => ['CookieArgs'],
        session_args => { cookie_name=>'my_session' },
    );
    my $session = $starch->session();
    my $cookie_args = $session->cookie_args();
    pritn $cookie_args->{name}; # my_session

=head1 DESCRIPTION

This session trait adds some utility methods to make it easier to write
code that tracks session state via a cookie.

=cut

use Types::Standard -types;
use Types::Common::String -types;

use Moo::Role;
use strictures 1;
use namespace::clean;

=head1 ARGUMENTS

Additional details about these arguments can be found in the
L<CGI::Simple::Cookie> documentation.

=head2 cookie_name

The name of the session cookie, defaults to C<session>.

=cut

has cookie_name => (
    is  => 'lazy',
    isa => NonEmptySimpleStr,
);
sub _build_cookie_name {
    return 'session';
}

=head2 cookie_expires

When this cookie should expire.  See the C<-expires> documentation in
L<CGI::Simple> and L<CGI::Simple::Cookie>.  Defaults to C<+1M> (one month).

=cut

has cookie_expires => (
    is  => 'lazy',
    isa => NonEmptySimpleStr | Undef,
);
sub _build_cookie_expires {
    return '+1M';
}

=head2 cookie_domain

The domain name to set the cookie to.  Set this to undef, or just don't set
it, to let the browser figure this out.

=cut

has cookie_domain => (
    is => 'lazy',
    isa => NonEmptySimpleStr | Undef,
);
sub _build_cookie_domain {
    return undef;
}

=head2 cookie_path

The path within the L</cookie_domain> that the cookie should be
applied to.  Defaults to C</>.

=cut

has cookie_path => (
    is  => 'lazy',
    isa => NonEmptySimpleStr,
);
sub _build_cookie_path {
    return '/';
}

=head2 cookie_secure

Whether the session cookie can only be transmitted over SSL.
This defaults to true, as doing otherwise is a pretty terrible
idea as a user's session cookie could be easly hijacker by
anyone sniffing network packets.

=cut

has cookie_secure => (
    is  => 'lazy',
    isa => Bool,
);
sub _build_cookie_secure {
    return 1;
}

=head2 cookie_http_only

If this is set to true then JavaScript will not have access to the cookie
data, mitigating certain XSS attacks.  This defaults to true as having
JavaScript that needs access to cookies is a rare case and you should
have to explicitly declare that you want to turn this protection off.

=cut

has cookie_http_only => (
    is  => 'lazy',
    isa => Bool,
);
sub _build_cookie_http_only {
    return 1;
}

=head1 METHODS

=head2 cookie_args

Returns L</cookie_expire_args> if the L<Web::Starch::Session/is_expired>, otherwise
returns L</cookie_set_args>.

These args are meant to be compatible with L</CGI::Simple::Cookie>, minus
the C<-> in front of the argument names, which is the same format that
Catalyst accepts for cookies.

=cut

sub cookie_args {
    my ($self) = @_;

    return $self->cookie_expire_args() if $self->is_expired();
    return $self->cookie_set_args();
}

=head2 cookie_set_args

Returns a hashref containing all the cookie args including the
value being set to L<Web::Starch::Session/key>.

=cut

sub cookie_set_args {
    my ($self) = @_;

    my $args = {
        name     => $self->cookie_name(),
        value    => $self->key(),
        expires  => $self->cookie_expires(),
        domain   => $self->cookie_domain(),
        path     => $self->cookie_path(),
        secure   => $self->cookie_secure(),
        httponly => $self->cookie_http_only(),
    };

    # Filter out undefined values.
    return {
        map { $_ => $args->{$_} }
        grep { defined $args->{$_} }
        keys( %$args )
    };
}

=head2 cookie_expire_args

This returns the same this as L</cookie_set_args>, but overrides the
C<expires> value to be C<-1d> which will trigger the client to remove
the cookie immediately.

=cut

sub cookie_expire_args {
    my ($self) = @_;

    return {
        %{ $self->cookie_set_args() },
        expires => '-1d',
    };
}

1;

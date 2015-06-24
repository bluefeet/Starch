package Web::Starch::Plugin::CookieArgs::Manager;

=head1 NAME

Web::Starch::Plugin::CookieArgs::Manager - Add arguments to the starch object
for dealing with HTTP cookies.

=head1 DESCRIPTION

This role adds methods to L<Web::Starch>.

See L<Web::Starch::Plugin::CookieArgs> for examples of using this
module.

=cut

use Types::Standard -types;
use Types::Common::String -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::ForManager
);

=head1 OPTIONAL ARGUMENTS

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

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.


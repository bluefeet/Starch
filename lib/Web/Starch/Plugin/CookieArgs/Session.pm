package Web::Starch::Plugin::CookieArgs::Session;

=head1 NAME

Web::Starch::Plugin::CookieArgs::Session - Add methods to the session object
for dealing with HTTP cookies.

=head1 DESCRIPTION

This role adds methods to L<Web::Starch::Session>.

See L<Web::Starch::Plugin::CookieArgs> for examples of using this
module.

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::ForSession
);

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
value being set to L<Web::Starch::Session/id>.

=cut

sub cookie_set_args {
    my ($self) = @_;

    my $args = {
        name     => $self->manager->cookie_name(),
        value    => $self->id(),
        expires  => $self->manager->cookie_expires(),
        domain   => $self->manager->cookie_domain(),
        path     => $self->manager->cookie_path(),
        secure   => $self->manager->cookie_secure(),
        httponly => $self->manager->cookie_http_only(),
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
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.


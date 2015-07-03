package Web::Starch::Role::MethodProxy;

=head1 NAME

Web::Starch::Role::MethodProxy - General purpose method proxy
support used internally by Starch.

=head1 DESCRIPTION

Any class that consumes this role will have their C<BUILDARGS> method
modified to call L</apply_method_proxies> on the arguments before the
object is constructed.

=cut

use Web::Starch::Util qw(
    apply_method_proxies
    call_method_proxy
    is_method_proxy
);

use Moo::Role;
use strictures 2;
use namespace::clean;

around BUILDARGS => sub{
    my $orig = shift;
    my $class = shift;

    if (@_ == 1 and is_method_proxy($_[0])) {
        return $class->$orig(
            call_method_proxy( $_[0] ),
        );
    }

    my $args = $class->$orig( @_ );

    return apply_method_proxies( $args );
};

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.


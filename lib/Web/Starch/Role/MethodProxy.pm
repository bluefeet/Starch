package Web::Starch::Role::MethodProxy;

=head1 NAME

Web::Starch::Role::MethodProxy - General purpose method proxy
support used internally by Starch.

=cut

use Carp qw( croak );
use Module::Runtime qw( require_module is_module_name );

use Moo::Role;
use strictures 2;
use namespace::clean;

=head1 BUILDARGS

Any class that consumes this role will have their C<BUILDARGS> method
modified to call L</apply_method_proxies> on the arguments before the
object is constructed.

=cut

around BUILDARGS => sub{
    my $orig = shift;
    my $class = shift;

    if (@_ == 1 and $class->is_method_proxy($_[0])) {
        return $class->$orig(
            $class->call_method_proxy( $_[0] ),
        );
    }

    my $args = $class->$orig( @_ );

    return $class->apply_method_proxies( $args );
};

=head1 CLASS METHODS

=head2 apply_method_proxies

Given a data structures (array ref or hash ref) this will recursively
find all method proxies, call then, and insert the return value back
into the data structure.

This creates a new data structure and does not modify the original.

=cut

sub apply_method_proxies {
    my ($class, $data) = @_;

    return $data if !ref $data;

    if (ref($data) eq 'HASH') {
        return {
            map { $_ => $class->apply_method_proxies( $data->{$_} ) }
            keys( %$data )
        };
    }
    elsif (ref($data) eq 'ARRAY') {
        if ($class->is_method_proxy( $data )) {
            return $class->call_method_proxy( $data );
        }

        return [
            map { $class->apply_method_proxies( $_ ) }
            @$data
        ];
    }

    return $data;
}

=head2 call_method_proxy

    my @ret = $class->call_method_proxy(
        [
            '&proxy'
            'Some::Package',
            'some_method',
            @args,
        ],
    );

Is the same as:

    require Some::Package;
    my @ret = Some::Package->some_method( @args );

Method proxies are defined in more detail at
L<Web::Starch::Manual/METHOD PROXIES>.

=cut

sub call_method_proxy {
    my ($class, $proxy) = @_;

    croak 'The method proxy is not an array ref with the first entry of "&proxy"'
        if !$class->is_method_proxy( $proxy );

    my ($marker, $package, $method, @args) = @$proxy;

    croak "The method proxy package is undefined"
        if !defined $package;
    croak "The method proxy method is undefined"
        if !defined $method;

    croak "The method proxy package, '$package', is not a valid package name"
        if !is_module_name( $package );

    require_module($package);

    croak "The method proxy package, '$package', does not support the '$method' method"
        if !$package->can( $method );

    return $package->$method( @args );
}

=head1 is_method_proxy

    $class->is_method_proxy( [ 'Foo', 'bar' ] ); # false
    $class->is_method_proxy( [ '&proxy', 'Foo', 'bar' ] ); # true

Returns true if the passed value is an array ref where the first value
is C<&proxy>.

=cut

sub is_method_proxy {
    my ($class, $proxy) = @_;
    return 0 if ref($proxy) ne 'ARRAY';
    return 1 if defined( $proxy->[0] ) and $proxy->[0] eq '&proxy';
    return 0;
}

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.


package Starch::Util;
use 5.008001;
use strictures 2;
our $VERSION = '0.10';

=head1 NAME

Starch::Util - Utility functions used internally by Starch.

=cut

use Carp qw();
use Module::Runtime qw( require_module is_module_name );
use Module::Find qw( findallmod );

use namespace::clean;

use Exporter qw( import );
our @EXPORT_OK;

=head1 FUNCTIONS

=head2 croak

This is a custom L<Carp> C<croak> function which sets various
standard starch packages as C<Internal> so that Carp looks
deeper in the stack for something to blame which makes exceptions
be more contextually useful for users of Starch and means we don't
need to use confess which generates giant stack traces.

=cut

my $all_modules;

push @EXPORT_OK, 'croak';
sub croak {
    $all_modules ||= [ findallmod('Starch') ];
    local @Carp::Internal{@$all_modules} = map { 1 } @$all_modules;
    return Carp::croak( @_ );
}

=head2 load_prefixed_module

    # These both return "Foo::Bar".
    my $module = load_prefixed_module( 'Foo', '::Bar' );
    my $module = load_prefixed_module( 'Foo', 'Foo::Bar' );

Takes a prefix to be appended to a relative package name and a
relative or absolute package name.  It then resolves the relative
package name to an absolute one, loads it, and returns the
absolute name.

=cut

push @EXPORT_OK, 'load_prefixed_module';
sub load_prefixed_module {
    my ($prefix, $module) = @_;

    $module = "$prefix$module" if $module =~ m{^::};

    require_module( $module );

    return $module;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut


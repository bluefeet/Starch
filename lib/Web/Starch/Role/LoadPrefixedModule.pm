package Web::Starch::Role::LoadPrefixedModule;

=head1 NAME

Web::Starch::Role::LoadPrefixedModule - Utility for loading relative
module names used internally by Starch.

=cut

use Module::Runtime qw( require_module );

use Moo::Role;
use strictures 2;
use namespace::clean;

=head1 CLASS METHODS

=head2 load_prefixed_module

    # These both return "Foo::Bar".
    my $module = $class->load_prefixed_module( 'Foo', '::Bar' );
    my $module = $class->load_prefixed_module( 'Foo', 'Foo::Bar' );

Takes a prefix to be appended to a relative package name and a
relative or absolute package name.  It then resolves the relative
package name to an absolute one, loads it, and returns the
absolute name.

=cut

sub load_prefixed_module {
    my ($class, $prefix, $module) = @_;

    $module = "$prefix$module" if $module =~ m{^::};

    require_module( $module );

    return $module;
}

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.


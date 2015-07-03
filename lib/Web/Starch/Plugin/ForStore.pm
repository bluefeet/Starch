package Web::Starch::Plugin::ForStore;

=head1 NAME

Web::Starch::Plugin::ForStore - Base role for Web::Starch::Store plugins.

=head1 SYNOPSIS

    package MyPlugin::Store;
    use Moo;
    with 'Web::Starch::Plugin::ForStore';
    sub foo { print 'bar' }

    my $starch = Web::Starch->new_with_plugins(
        ['MyPlugin::Store'],
        ...,
    );
    $starch->store->foo(); # bar

=head1 DESCRIPTION

This role provides no additional functionality to
store plugins.  All it does is labels a plugin as a store
plugin so that Starch knows which class type it applies to.

See L<Web::Starch::Manual::Extending/PLUGINS> for more information
on writing plugins.

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.


package Web::Starch::Plugin::ForManager;

=head1 NAME

Web::Starch::Plugin::ForManager - Base role for Web::Starch plugins.

=head1 SYNOPSIS

    package MyPlugin::Manager;
    use Moo;
    with 'Web::Starch::Plugin::ForManager';
    has foo => ( is=>'ro' );

    my $starch = Web::Starch->new_with_plugins(
        ['MyPlugin::Manager'],
        foo => 'bar',
        ...,
    );
    print $starch->foo(); # bar

=head1 DESCRIPTION

This role provides no additional functionality to
manager plugins.  All it does is labels a plugin as a manager
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


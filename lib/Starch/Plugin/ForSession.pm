package Starch::Plugin::ForSession;

=head1 NAME

Starch::Plugin::ForSession - Base role for Starch::Session plugins.

=head1 SYNOPSIS

    package MyPlugin::Session;
    use Moo;
    with 'Starch::Plugin::ForSession';
    sub foo { print 'bar' }

    my $starch = Starch->new_with_plugins(
        ['MyPlugin::Session'],
        ...,
    );
    $starch->session->foo(); # bar

=head1 DESCRIPTION

This role provides no additional functionality to
session plugins.  All it does is labels a plugin as a session
plugin so that Starch knows which class type it applies to.

See L<Starch::Manual::Extending/PLUGINS> for more information
on writing plugins.

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.


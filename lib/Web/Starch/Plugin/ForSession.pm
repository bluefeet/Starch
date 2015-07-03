package Web::Starch::Plugin::ForSession;

=head1 NAME

Web::Starch::Plugin::ForSession - Base role for Web::Starch::Session plugins.

=head1 SYNOPSIS

    package MyPlugin::Session;
    use Moo;
    with 'Web::Starch::Plugin::ForSession';
    sub foo { print 'bar' }

    my $starch = Web::Starch->new_with_plugins(
        ['MyPlugin::Session'],
        ...,
    );
    $starch->session->foo(); # bar

=head1 DESCRIPTION

This role provides no additional functionality to
session plugins.  All it does is labels a plugin as a session
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


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

This role, currently, provides no additional functionality to
session plugins.  All it does is labels a plugin as a session
plugin so that starch knows which class type it applies to.

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

1;

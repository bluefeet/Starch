package Starch::Plugin::ForState;
our $VERSION = '0.13';

=head1 NAME

Starch::Plugin::ForState - Base role for Starch::State plugins.

=head1 SYNOPSIS

    package MyPlugin::State;
    use Moo;
    with 'Starch::Plugin::ForState';
    sub foo { print 'bar' }

    my $starch = Starch->new(
        plugins => ['MyPlugin::State'],
        ...,
    );
    $starch->state->foo(); # bar

=head1 DESCRIPTION

This role provides no additional functionality to
state plugins.  All it does is labels a plugin as a state
plugin so that Starch knows which class type it applies to.

See L<Starch::Extending/PLUGINS> for more information.

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

1;
__END__

=head1 SUPPORT

See L<Starch/SUPPORT>.

=head1 AUTHORS

See L<Starch/AUTHORS>.

=head1 LICENSE

See L<Starch/LICENSE>.

=cut


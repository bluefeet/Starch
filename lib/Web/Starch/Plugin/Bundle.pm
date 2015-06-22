package Web::Starch::Plugin::Bundle;

use Moo::Role qw();
use Types::Standard -types;
use Module::Runtime qw( require_module );

use Moo::Role;
use strictures 2;
use namespace::clean;

sub _load_module {
    my ($prefix, $module) =  @_;
    $module = "$prefix$module" if $module =~ m{^::};
    require_module( $module );
    return $module;
}

has plugins => (
    is       => 'lazy',
    isa      => ArrayRef[ Str ],
    init_arg => undef,
    builder  => 'bundled_plugins',
);

has resolved_plugins => (
    is       => 'lazy',
    isa      => ArrayRef[ ClassName | RoleName ],
    init_arg => undef,
);
sub _build_resolved_plugins {
    my ($self) = @_;

    my @plugins;
    foreach my $plugin (@{ $self->plugins() }) {
        push @plugins, _load_module(
            'Web::Starch::Plugin',
            $plugin,
        );
    }

    return \@plugins;
}

has roles => (
    is       => 'lazy',
    isa      => ArrayRef[ RoleName ],
    init_arg => undef,
);
sub _build_roles {
    my ($self) = @_;

    my @roles;

    foreach my $plugin (@{ $self->resolved_plugins() }) {
        if (Moo::Role::does_role( $plugin, 'Web::Starch::Plugin::Bundle')) {
            die "Plugin bundle $plugin is not a class"
                if !$plugin->can('new');

            my $bundle = $plugin->new();
            push @roles, @{ $bundle->roles() };
        }
        else {
            die "Plugin $plugin does not look like a role"
                if $plugin->can('new');

            push @roles, $plugin;
        }
    }

    return \@roles;
}

1;

package Web::Starch::Plugin::Bundle;

=head1 NAME

Web::Starch::Plugin::Bundle - Base role for Web::Starch plugin bundles.

=head1 SYNOPSIS

    # Make a manager plugin.
    package MyPlugin::Manager;
    use Moo::Role;
    with 'Web::Starch::Plugin::ForManager';
    has foo => ( is=>'ro' );

    # Make a store plugin.
    package MyPlugin::Store;
    use Moo::Role;
    with 'Web::Starch::Plugin::ForStore';
    has foo => ( is=>'ro' );

    # Make a session plugin.
    package MyPlugin::Session;
    use Moo::Role;
    with 'Web::Starch::Plugin::ForSession';
    sub print_manager_foo {
        my ($self) = @_;
        print $self->manager->foo();
    }
    sub print_store_foo {
        my ($self) = @_;
        print $self->manager->store->foo();
    }

    # Bundle the plugins together.
    package MyPlugin;
    use Moo;
    with 'Web::Starch::Plugin::Bundle';
    sub bundled_plugins {
        return ['MyPlugin::Manager', 'MyPlugin::Store', 'MyPlugin::Session'];
    }

    # Use the bundle.
    my $starch = Web::Starch->new_with_plugins(
        ['MyPlugin'],
        store => { class=>'::Memory', foo=>'FOO_STORE' },
        foo => 'FOO_MANAGER',
    );
    my $session = $starch->session();
    $session->print_manager_foo(); # FOO_MANAGER
    $session->print_store_foo(); # FOO_STORE

=head1 DESCRIPTION

=cut

use Moo::Role qw();
use Types::Standard -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Role::LoadPrefixedModule
);

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
        push @plugins, $self->load_prefixed_module(
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
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.


#!/usr/bin/env perl
use strictures 2;

use Test::More;

use Starch;

{
    package MyPlugin::Manager;
    use Moo::Role;
    with 'Starch::Plugin::ForManager';
    sub my_manager_plugin { 1 }
}

{
    package MyPlugin::Session;
    use Moo::Role;
    with 'Starch::Plugin::ForSession';
    sub my_session_plugin { 1 }
}

{
    package MyPlugin::Store;
    use Moo::Role;
    with 'Starch::Plugin::ForStore';
    sub my_store_plugin { 1 }
}

{
    package MyPlugin;
    use Moo;
    with 'Starch::Plugin::Bundle';
    sub bundled_plugins {
        ['MyPlugin::Manager', 'MyPlugin::Session', 'MyPlugin::Store'];
    }
}

subtest bundle => sub{
    my $starch = Starch->new_with_plugins(
        ['MyPlugin'],
        store => { class => '::Memory' },
    );

    can_ok( $starch, 'my_manager_plugin' );
    can_ok( $starch->session(), 'my_session_plugin' );
    can_ok( $starch->store(), 'my_store_plugin' );
};

subtest individual => sub{
    my $starch = Starch->new_with_plugins(
        ['MyPlugin::Manager', 'MyPlugin::Store'],
        store => { class => '::Memory' },
    );

    can_ok( $starch, 'my_manager_plugin' );
    can_ok( $starch->store(), 'my_store_plugin' );

    ok(
        (!$starch->session->can('my_session_plugin')),
        '!' . $starch->factory->session_class() . q[->can('my_session_plugin')],
    );
};

done_testing;

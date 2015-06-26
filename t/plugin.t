#!/usr/bin/env perl
use strictures 2;

use Test::More;

use Web::Starch;

{
    package MyPlugin::Manager;
    use Moo::Role;
    with 'Web::Starch::Plugin::ForManager';
    sub my_manager_plugin { 1 }
}

{
    package MyPlugin::Session;
    use Moo::Role;
    with 'Web::Starch::Plugin::ForSession';
    sub my_session_plugin { 1 }
}

{
    package MyPlugin::Store;
    use Moo::Role;
    with 'Web::Starch::Plugin::ForStore';
    sub my_store_plugin { 1 }
}

{
    package MyPlugin;
    use Moo;
    with 'Web::Starch::Plugin::Bundle';
    sub bundled_plugins {
        ['MyPlugin::Manager', 'MyPlugin::Session', 'MyPlugin::Store'];
    }
}

subtest bundle => sub{
    my $starch = Web::Starch->new_with_plugins(
        ['MyPlugin'],
        store => { class => '::Memory' },
    );

    can_ok( $starch, 'my_manager_plugin' );
    can_ok( $starch->session(), 'my_session_plugin' );
    can_ok( $starch->store(), 'my_store_plugin' );
};

subtest individual => sub{
    my $starch = Web::Starch->new_with_plugins(
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

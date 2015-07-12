#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Starch;
use Starch;

Test::Starch->new(
    plugins => ['::DisableStore'],
)->test();

my $enabled_store = Starch->new(
    store => {
        class => '::Memory',
        global => 1,
    },
)->store();

my $disabled_store = Starch->new_with_plugins(
    ['::DisableStore'],
    store => {
        class=>'::Memory',
        global => 1,
        disable_set => 1,
        disable_get => 1,
        disable_remove => 1,
    },
)->store();

$enabled_store->set('foo1', [], {bar=>1}, 10);
$disabled_store->set('foo2', [], {bar=>2}, 10);

is_deeply( $enabled_store->get('foo1', []), {bar=>1}, 'set and get are enabled' );
is( $disabled_store->get('foo1', []), undef, 'get is disabled' );
is( $enabled_store->get('foo2', []), undef, 'set is disabled' );

$enabled_store->set('foo2', [], {bar=>2}, 10);

$enabled_store->remove('foo1', []);
$disabled_store->remove('foo2', []);

is( $enabled_store->get('foo1', []), undef, 'remove is enabled' );
is_deeply( $enabled_store->get('foo2', []), {bar=>2}, 'remove is disabled' );

done_testing();

#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Fatal;

use Web::Starch;

subtest id => sub{
    my $starch = starch();

    my $session1 = $starch->session();
    my $session2 = $starch->session();
    my $session3 = $starch->session( '1234' );

    like( $session1->id(), qr{^\S+$}, 'ID looks good' );
    isnt( $session1->id(), $session2->id(), 'two generated session IDs are not the same' );
    is( $session3->id(), '1234', 'custom ID was used' );
};

subtest expires => sub{
    my $starch = starch( expires=>32 );
    my $session = $starch->session();
    is( $session->expires(), 32, 'session expires inherited the global expires' );
};

subtest modified => sub{
    my $starch = starch();
    my $session = $starch->session();
    is( $session->modified(), $session->created(), 'modfied is same as created in new session' );
    sleep 2;
    $session->force_save();
    $session = $starch->session( $session->id() );
    cmp_ok( $session->modified(), '>', $session->created(), 'modified was updated with save' );
};

subtest created => sub{
    my $starch = starch();
    my $start_time = time();
    my $session = $starch->session();
    my $created_time = $session->created();
    cmp_ok( $created_time, '>=', $start_time, 'session created on or after test start' );
    cmp_ok( $created_time, '<=', $start_time+1, 'session created is on or just after test start' );
    sleep 2;
    $session->force_save();
    $session = $starch->session( $session->id() );
    is( $session->created(), $created_time, 'created was updated with save' );
};

subtest in_store => sub{
    my $starch = starch();

    my $session1 = $starch->session();
    my $session2 = $starch->session( $session1->id() );

    is( $session1->in_store(), 0, 'new session is_new' );
    is( $session2->in_store(), 1, 'existing session is not is_new' );
};

subtest is_deleted => sub{
    my $starch = starch();

    my $session = $starch->session();
    is( $session->is_deleted(), 0, 'new session is not deleted' );
    $session->force_save();
    $session->delete();
    is( $session->is_deleted(), 1, 'deleted session is deleted' );
};

subtest is_dirty => sub{
    my $starch = starch();

    my $session = $starch->session();
    is( $session->is_dirty(), 0, 'new session is not is_dirty' );
    $session->data->{foo} = 543;
    is( $session->is_dirty(), 1, 'modified session is_dirty' );
};

subtest is_loaded => sub{
    my $starch = starch();
    my $session = $starch->session();
    ok( (!$session->is_loaded()), 'session is not loaded' );
    $session->data();
    ok( $session->is_loaded(), 'session is loaded' );
};

subtest is_saved => sub{
    my $starch = starch();
    my $session = $starch->session();
    ok( (!$session->is_saved()), 'session is not saved' );
    $session->force_save();
    ok( $session->is_saved(), 'session is saved' );
};

subtest save => sub{
    my $starch = starch();

    my $session1 = $starch->session();

    $session1->data->{foo} = 789;
    my $session2 = $starch->session( $session1->id() );
    is( $session2->data->{foo}, undef, 'new session did not receive data from old' );

    is( $session1->is_dirty(), 1, 'is dirty before save' );
    $session1->save();
    is( $session1->is_dirty(), 0, 'is not dirty after save' );
    $session2 = $starch->session( $session1->id() );
    is( $session2->data->{foo}, 789, 'new session did receive data from old' );
};

subtest force_save => sub{
    my $starch = starch();

    my $session = $starch->session();

    $session->data->{foo} = 931;
    $session->save();

    $session = $starch->session( $session->id() );
    $session->data();

    $starch->session( $session->id() )->delete();

    $session->save();
    is(
        $starch->session( $session->id() )->data->{foo},
        undef,
        'save did not save',
    );

    $session->force_save();
    is(
        $starch->session( $session->id() )->data->{foo},
        931,
        'force_save did save',
    );
};

subtest reload => sub{
    my $starch = starch();
    my $session = $starch->session();
    is( exception { $session->reload() }, undef, 'reloading a non-dirty session did not fail' );
    $session->data->{foo} = 2;
    like( exception { $session->reload() }, qr{dirty}, 'reloading a dirty session failed' );
};

subtest force_reload => sub{
    my $starch = starch();
    my $session1 = $starch->session();
    $session1->data->{foo} = 91;
    $session1->save();
    my $session2 = $starch->session( $session1->id() );
    $session2->data->{foo} = 19;
    $session2->save();
    $session1->reload();
    is( $session1->data->{foo}, 19, 'reload worked' );
};

subtest mark_clean => sub{
    my $starch = starch();

    my $session = $starch->session();
    $session->data->{foo} = 6934;
    is( $session->is_dirty(), 1, 'is dirty' );
    $session->mark_clean();
    is( $session->is_dirty(), 0, 'is clean' );
    is( $session->data->{foo}, 6934, 'data is intact' );
};

subtest rollback => sub{
    my $starch = starch();

    my $session = $starch->session();
    $session->data->{foo} = 6934;
    is( $session->is_dirty(), 1, 'is dirty' );
    $session->rollback();
    is( $session->is_dirty(), 0, 'is clean' );
    is( $session->data->{foo}, undef, 'data is rolled back' );

    $session->data->{foo} = 23;
    $session->mark_clean();
    $session->data->{foo} = 95;
    $session->rollback();
    is( $session->data->{foo}, 23, 'rollback to previous mark_clean' );
};

subtest delete => sub{
    my $starch = starch();
    my $session = $starch->session();
    like( exception { $session->delete() }, qr{stored}, 'calling delete on un-stored session fails' );
    $session->force_save();
    is( exception { $session->delete() }, undef, 'deleting a stored session does not fail' );
};

subtest force_delete => sub{
    my $starch = starch();

    my $session = $starch->session();
    $session->data->{foo} = 39;
    $session->save();

    $session = $starch->session( $session->id() );
    is( $session->data->{foo}, 39, 'session persists' );

    $session->delete();
    $session = $starch->session( $session->id() );
    is( $session->data->{foo}, undef, 'session was deleted' );
};

subtest set_expires => sub{
    my $starch = starch( expires=>222 );
    my $session = $starch->session();
    is( $session->expires(), 222, 'double check a new session gets the global expires' );
    $session->set_expires( 111 );
    $session->save();
    $session = $starch->session( $session->id() );
    is( $session->expires(), 111, 'custom expires was saved' );
};

subtest hash_seed => sub{
    my $starch = starch();

    my $session = $starch->session();
    isnt( $session->hash_seed(), $session->hash_seed(), 'two hash seeds are not the same' );
};

subtest digest => sub{
    my $starch = starch();

    my $session = $starch->session();
    my $d1 = $session->digest();
    my $d2 = $session->digest();
    isnt( $d1, $d2, 'two digest objects are not the same' );
};

subtest generate_id => sub{
    my $starch = starch();
    my $session = $starch->session();

    isnt(
        $session->generate_id(),
        $session->generate_id(),
        'two generated ids are not the same',
    );
};

subtest reset_id => sub{
    my $starch = starch();
    my $session = $starch->session();

    $session->data->{foo} = 54;
    ok( $session->is_dirty(), 'session is dirty before save' );
    $session->save();
    ok( (!$session->is_dirty()), 'session is not dirty after save' );
    ok( $session->is_saved(), 'session is marked saved after save' );

    my $old_id = $session->id();
    $session->reset_id();
    ok( (!$session->is_saved()), 'session is not marked saved after reset_id' );
    ok( $session->is_dirty(), 'session is marked dirty after reset_id' );
    isnt( $session->id(), $old_id, 'session has new id after reset_id' );
    $session->save();

    my $old_session = $starch->session( $old_id );
    is( $old_session->data->{foo}, undef, 'old session data was deleted' );
};

subtest clone_data => sub{
    my $starch = starch();
    my $session = $starch->session();

    my $old_data = { foo=>32, bar=>[1,2,3] };
    my $new_data = $session->clone_data( $old_data );

    is_deeply( $new_data, $old_data, 'cloned data matches source data' );

    isnt( "$old_data->{bar}", "$new_data->{bar}", 'clone data structure has different reference' );
};

done_testing;

sub starch {
    return Web::Starch->new(
        store => {
            class => '::Memory',
        },
        @_,
    );
}

#!/usr/bin/env perl
use strictures 1;

use Test::More;

use Web::Starch;

use Web::Starch::Store::Memory;

my $starch = Web::Starch->new(
    store => {
        class => 'Memory',
    },
);

subtest key => sub{
    my $session1 = $starch->session();
    my $session2 = $starch->session();
    my $session3 = $starch->session( '1234' );

    like( $session1->key(), qr{^\S+$}, 'key looks good' );
    isnt( $session1->key(), $session2->key(), 'two generated session keys are not the same' );
    is( $session3->key(), '1234', 'custom key was used' );
};

subtest is_new => sub{
    my $session1 = $starch->session();
    my $session2 = $starch->session( $session1->key() );

    is( $session1->is_new(), 1, 'new session is_new' );
    is( $session2->is_new(), 0, 'existing session is not is_new' );
};

subtest is_deleted => sub{
    my $session = $starch->session();
    is( $session->is_deleted(), 0, 'new session is not is_deleted' );
    $session->delete();
    is( $session->is_deleted(), 1, 'deleted session is is_deleted' );
};

subtest is_dirty => sub{
    my $session = $starch->session();
    is( $session->is_dirty(), 0, 'new session is not is_dirty' );
    $session->data->{foo} = 543;
    is( $session->is_dirty(), 1, 'modified session is_dirty' );
};

subtest flush => sub{
    my $session1 = $starch->session();

    $session1->data->{foo} = 789;
    my $session2 = $starch->session( $session1->key() );
    is( $session2->data->{foo}, undef, 'new session did not receive data from old' );

    is( $session1->is_dirty(), 1, 'is dirty before flush' );
    $session1->flush();
    is( $session1->is_dirty(), 0, 'is not dirty after flush' );
    $session2 = $starch->session( $session1->key() );
    is( $session2->data->{foo}, 789, 'new session did receive data from old' );
};

subtest force_flush => sub{
    my $session = $starch->session();

    $session->data->{foo} = 931;
    $session->flush();

    $starch->session( $session->key() )->delete();

    $session->flush();
    is(
        $starch->session( $session->key() )->data->{foo},
        undef,
        'flush did not flush',
    );

    $session->force_flush();
    is(
        $starch->session( $session->key() )->data->{foo},
        931,
        'force_flush did flush',
    );
};

subtest mark_clean => sub{
    my $session = $starch->session();
    $session->data->{foo} = 6934;
    is( $session->is_dirty(), 1, 'is dirty' );
    $session->mark_clean();
    is( $session->is_dirty(), 0, 'is clean' );
    is( $session->data->{foo}, 6934, 'data is intact' );
};

subtest rollback => sub{
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
    my $session = $starch->session();
    $session->data->{foo} = 39;
    $session->flush();

    $session = $starch->session( $session->key() );
    is( $session->data->{foo}, 39, 'session persists' );

    $session->delete();
    $session = $starch->session( $session->key() );
    is( $session->data->{foo}, undef, 'session was deleted' );
};

subtest hash_seed => sub{
    my $session = $starch->session();
    isnt( $session->hash_seed(), $session->hash_seed(), 'two hash seeds are not the same' );
};

subtest digest => sub{
    my $session = $starch->session();
    my $d1 = $session->digest();
    my $d2 = $session->digest();
    isnt( $d1, $d2, 'two digest objects are not the same' );
};

done_testing;

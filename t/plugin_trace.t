#!/usr/bin/env perl
use strictures 2;

# If this test fails it may not be due to obvious breakage, but instead
# due to a change in how the various starch objects are created which
# could be a breakage or cause for fixing this test.

use Test::More;
use Log::Any::Test;
use Log::Any qw($log);

use Test::Starch;
use Starch;

Test::Starch->new(
    plugins => ['::Trace'],
)->test();
$log->clear();

my $starch = Starch->new_with_plugins(
    ['::Trace'],
    store => { class => '::Memory' },
);

my $manager_class = 'Starch';
my $session_class = 'Starch::Session';
my $store_class   = 'Starch::Store::Memory';

subtest 'manager created with store' => sub{
    $log->category_contains_ok(
        $manager_class,
        qr{^starch\.manager\.new$},
        'starch.manager.new',
    );
    $log->category_contains_ok(
        $store_class,
        qr{^starch\.store\.Memory\.new$},
        'starch.store.Memory.new',
    );
    log_empty_ok();
};

subtest 'create session' => sub{
    my $session = $starch->session();
    my $session_id = $session->id();

    $log->category_contains_ok(
        $session_class,
        qr{^starch\.session\.new\.$session_id$},
        'starch.session.new.$session_id',
    );
    $log->category_contains_ok(
        $session_class,
        qr{^starch\.session\.generate_id\.$session_id$},
        'starch.session.generate_id.$session_id',
    );
    $log->category_contains_ok(
        $manager_class,
        qr{^starch\.manager.session\.created\.$session_id$},
        'starch.manager.session.created.$session_id',
    );
    log_empty_ok();
};

subtest 'retrieve session' => sub{
    my $session = $starch->session('1234');
    my $session_id = $session->id();

    $log->category_contains_ok(
        $session_class,
        qr{^starch\.session\.new\.$session_id$},
        'starch.session.new.$session_id',
    );
    $log->category_contains_ok(
        $manager_class,
        qr{^starch\.manager.session\.retrieved\.$session_id$},
        'starch.manager.session.retrieved.$session_id',
    );
    log_empty_ok();
};

subtest 'session methods' => sub{
    my $session = $starch->session();
    my $session_id = $session->id();
    $log->clear();

    $session->save();
    log_empty_ok('log is empty after non-dirty save');

    $session->data->{foo} = 34;
    $session->save();
    $log->category_contains_ok(
        $session_class,
        qr{^starch\.session\.save\.$session_id$},
        'starch.session.save.$session_id',
    );
    $log->category_contains_ok(
        $store_class,
        qr{^starch\.store\.Memory\.set\.$session_id$},
        'starch.store.Memory.set.$session_id',
    );
    $log->category_contains_ok(
        $session_class,
        qr{^starch\.session\.mark_clean\.$session_id$},
        'starch.session.mark_clean.$session_id',
    );
    log_empty_ok();

    $session->reload();
    $session->mark_clean();
    $session->rollback();
    $session->delete();

    $log->category_contains_ok(
        $session_class,
        qr{^starch\.session\.reload\.$session_id$},
        'starch.session.reload.$session_id',
    );
    $log->category_contains_ok(
        $session_class,
        qr{^starch\.session\.mark_clean\.$session_id$},
        'starch.session.mark_clean.$session_id',
    );
    $log->category_contains_ok(
        $session_class,
        qr{^starch\.session\.rollback\.$session_id$},
        'starch.session.rollback.$session_id',
    );
    $log->category_contains_ok(
        $store_class,
        qr{^starch\.store\.Memory\.get\.$session_id$},
        'starch.store.Memory.get.$session_id',
    );
    $log->category_contains_ok(
        $session_class,
        qr{^starch\.session\.delete\.$session_id$},
        'starch.session.delete.$session_id',
    );
    $log->category_contains_ok(
        $store_class,
        qr{^starch\.store\.Memory\.remove\.$session_id$},
        'starch.store.Memory.remove.$session_id',
    );
    log_empty_ok();

};

done_testing;

# Workaround: https://github.com/dagolden/Log-Any/issues/30
sub log_empty_ok {
    my ($test_msg) = @_;
    $test_msg = 'log is empty' if !defined $test_msg;
    my $msgs = $log->msgs();
    ok( (@$msgs == 0), $test_msg );
    use Data::Dumper;
    diag( Dumper($msgs) ) if @$msgs;
    $log->clear();
}

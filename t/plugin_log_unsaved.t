#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Starch;
use Log::Any::Test;
use Log::Any qw($log);
use Starch;

Test::Starch->new(
    plugins => ['::LogUnsaved'],
)->test();
$log->clear();

subtest 'without log' => sub{
    my $starch = Starch->new(
        store => { class => '::Memory' },
    );

    $starch->session->data->{foo} = 94;
    sleep 1;
    log_empty_ok();
};

subtest 'with log' => sub{
    my $starch = Starch->new_with_plugins(
        ['::LogUnsaved'],
        store => { class => '::Memory' },
    );

    $starch->session->data->{foo} = 94;
    sleep 1;
    $log->category_contains_ok(
        $starch->factory->base_session_class(),
        qr{was changed and not saved},
        'found log',
    );
    log_empty_ok();
};

done_testing();

# Workaround: https://github.com/dagolden/Log-Any/issues/30
sub log_empty_ok {
    my ($test_msg) = @_;
    $test_msg = 'log is empty' if !defined $test_msg;
    my $msgs = $log->msgs();
    ok( (@$msgs == 0), $test_msg );
    use Data::Dumper;
    diag( Dumper($msgs) ) if @$msgs;
}

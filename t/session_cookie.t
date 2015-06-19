#!/usr/bin/env perl
use strictures 1;

use Test::More;

use Web::Starch;

use Web::Starch::Store::Memory;

my $starch = Web::Starch->new(
    store => { class => 'Memory' },
    session_traits => [ 'Cookie' ],
    session_args => {
        cookie_name      => 'foo-session',
        cookie_expires   => '+1d',
        cookie_domain    => 'foo.example.com',
        cookie_path      => '/bar',
        cookie_secure    => 0,
        cookie_http_only => 0,
    },
);

subtest cookie_args => sub{
  my $session = $starch->session();

  my $args = $session->cookie_args();
  is( $args->{name}, 'foo-session', 'cookie name is correct' );
  is( $args->{value}, $session->key(), 'cookie value is session key' );
  is( $args->{expires}, '+1d', 'cookie expires is correct' );
  is( $args->{domain}, 'foo.example.com', 'cookie domain is correct' );
  is( $args->{path}, '/bar', 'cookie path is correct' );
  is( $args->{secure}, 0, 'cookie secure is correct' );
  is( $args->{httponly}, 0, 'cookie httponly is correct' );

  $session->delete();

  $args = $session->cookie_args();
  is( $args->{name}, 'foo-session', 'deleted cookie name is correct' );
  is( $args->{value}, $session->key(), 'deleted cookie value is session key' );
  is( $args->{expires}, '-1d', 'deleted cookie expires is correct' );
  is( $args->{domain}, 'foo.example.com', 'deleted cookie domain is correct' );
  is( $args->{path}, '/bar', 'deleted cookie path is correct' );
  is( $args->{secure}, 0, 'deleted cookie secure is correct' );
  is( $args->{httponly}, 0, 'deleted cookie httponly is correct' );
};

subtest set_cookie_args => sub{
  my $session = $starch->session();

  my $args = $session->set_cookie_args();
  is( $args->{expires}, '+1d', 'new session cookie expires is good' );

  $session->delete();
  $args = $session->set_cookie_args();
  is( $args->{expires}, '+1d', 'deleted session cookie expires is good' );
};

subtest delete_cookie_args => sub{
  my $session = $starch->session();

  my $args = $session->delete_cookie_args();
  is( $args->{expires}, '-1d', 'new session cookie expires is good' );

  $session->delete();
  $args = $session->delete_cookie_args();
  is( $args->{expires}, '-1d', 'deleted session cookie expires is good' );
};

done_testing;

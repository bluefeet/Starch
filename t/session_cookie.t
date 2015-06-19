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

  $session->expire();

  $args = $session->cookie_args();
  is( $args->{name}, 'foo-session', 'expired cookie name is correct' );
  is( $args->{value}, $session->key(), 'expired cookie value is session key' );
  is( $args->{expires}, '-1d', 'expired cookie expires is correct' );
  is( $args->{domain}, 'foo.example.com', 'expired cookie domain is correct' );
  is( $args->{path}, '/bar', 'expired cookie path is correct' );
  is( $args->{secure}, 0, 'expired cookie secure is correct' );
  is( $args->{httponly}, 0, 'expired cookie httponly is correct' );
};

subtest set_cookie_args => sub{
  my $session = $starch->session();

  my $args = $session->set_cookie_args();
  is( $args->{expires}, '+1d', 'new session cookie expires is good' );

  $session->expire();
  $args = $session->set_cookie_args();
  is( $args->{expires}, '+1d', 'expired session cookie expires is good' );
};

subtest expire_cookie_args => sub{
  my $session = $starch->session();

  my $args = $session->expire_cookie_args();
  is( $args->{expires}, '-1d', 'new session cookie expires is good' );

  $session->expire();
  $args = $session->expire_cookie_args();
  is( $args->{expires}, '-1d', 'expired session cookie expires is good' );
};

done_testing;

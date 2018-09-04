requires 'strictures'       => 2.000000;
requires 'namespace::clean' => 0.24;
requires 'Moo'              => 2.000000;
requires 'Type::Tiny'       => 1.000005;
requires 'Module::Runtime'  => 0.014;
requires 'Log::Any'         => 1.03;
requires 'Try::Tiny'        => 0.18;
requires 'MooX::BuildArgs'  => 0.02;

requires 'Carp'             => 0;
requires 'Scalar::Util'     => 0;
requires 'Storable'         => 0;
requires 'Digest::SHA'      => 0;

on test => sub {
    requires 'Test2::V0' => '0.000094';
};


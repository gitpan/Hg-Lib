#!perl

use strict;
use warnings;

use t::common;

use Test::More;
use Test::Fatal;

use Hg::Lib::Server;

use Hg::Lib::Exception -aliases;

sub fnew { Hg::Lib::Server->new( hg => fake_hg, connect => 1, @_ ) }

subtest 'timeout' => sub {

    my $e = exception { fnew( args => [qw( wait )], timeout => 0.01 ) };

    isa_ok( $e,                     EHandshake,   'handshake' );
    isa_ok( $e->previous_exception, EPipeTimeout, 'Timeout' );

};

subtest 'bad length' => sub {

    my $e = exception { fnew( args => ['badlen'] ) };

    isa_ok( $e,                     EHandshake, 'handshake' );
    isa_ok( $e->previous_exception, EPipeEOF,   'EOF' );
    like( $e, qr/end-of-file/, 'message' );

};

subtest 'fail with stderr' => sub {

    my $e = exception { fnew( args => ['fail_with_stderr'] )->close  };

    isa_ok( $e, EPipeTerminated, 'Terminated' );
    like( $e, qr/unexpected termination/, 'message' );
    like( $e, qr/Message from Server on STDERR/, 'stderr' );

};

subtest 'exit with stderr' => sub {

    my $e = exception { fnew( args => ['exit_with_stderr'] )->close  };

    isa_ok( $e,                     EPipeStderr, 'EPipeStderr' );
    like( $e, qr/Message from Server on STDERR/, 'stderr' );

};

done_testing;



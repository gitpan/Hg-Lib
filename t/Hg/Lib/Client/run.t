#! perl

use strict;
use warnings;

use 5.10.1;

use lib 't/lib';

use base 'Test::Hg::Lib::Client';

use boolean;
use Test::More;
use Test::Fatal;
use Safe::Isa;

use Hg::Lib::Client;
use Hg::Lib::Exception -aliases;

use YAML::Tiny;

INIT { Test::Class->runtests }


# test the output channel handler
sub echo_output : Tests {

    my $self = shift;

    my $out = YAML::Tiny->read_string(
        $self->{client}->run( [ 'echo_output', '--a', 3 ] )->output );

    is_deeply(
        $out->[0],
        {
            cmd  => 'echo_output',
            args => [ '--a', 3 ]
        },
        "echo_output, args: --a 3"
    );

}

sub failed_without_error_handler : Tests {

    my $self = shift;

    my $e = exception { $self->{client}->run( ['fail'] ) };

    isa_ok( $e, ECommand, 'ECommand' );

    my $res = $e->result;

    is( $res->output, undef,     'no output on failure' );
    is( $res->error,  'failed!', 'error output on failure' );
    is( $res->ret,    193,       'error code' );
}

sub failed_with_error_handler : Tests {

    my $self = shift;

    my $res;

    my $e = exception {
        $self->{client}
          ->run( ['fail'], eh => sub {  $res = shift } );
    };

    is( $e, undef, 'no exception' );

    is( $res->output, undef,     'no output on failure' );
    is( $res->error,  'failed!', 'error output on failure' );
    is( $res->ret,    193,       'error code' );
}

sub L_handler : Tests {

    my $self = shift;

    my $msg    = 'Please enter something';
    my $prompt = sub {
        my $length = shift;

        state $i = 5;

        is( $length, 4096, "requested length\n" );

        is( $_[0], $msg, 'output channel' );

        return $i ? sprintf( "%03d\n", $i-- ) : '';
    };

    my $result;
    my $e = exception {
        $result = $self->{client}->run( ['read_line'], prompt => $prompt );
    };

    is( $e, undef, 'no exception' );
    ok( $result->$_isa( 'Hg::Lib::Client::Result') , "populated result object" )
      or return;
    is( $result->output, "${msg}001\n002\n003\n004\n005\n", 'returned message' );

}

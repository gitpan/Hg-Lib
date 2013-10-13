#! perl

use strict;
use warnings;

use Test::More;

use boolean;
use Hg::Lib::Utils 'prep_cmd';


subtest 'long/short dashes' => sub {

    is_deeply( prep_cmd( 'cmd', { s => true } ), [qw( cmd -s )], 'short' );
    is_deeply( prep_cmd( 'cmd', { long => true } ), [qw( cmd --long )], 'long' );

};

subtest 'bool/undef/scalar values' => sub {

    is_deeply( prep_cmd( 'cmd', { a => true } ),
        [qw( cmd -a )], 'short bool true' );

    is_deeply( prep_cmd( 'cmd', { a => false } ), ['cmd'], 'short bool false' );

    is_deeply( prep_cmd( 'cmd', { a => undef } ), ['cmd'], 'short bool undef' );


    is_deeply( prep_cmd( 'cmd', { a => 1 } ), [qw( cmd -a 1 )], 'short int 1' );

    is_deeply( prep_cmd( 'cmd', { a => 0 } ), [qw( cmd -a 0 )], 'short int 0' );

    is_deeply(
        prep_cmd( 'cmd', { a => '' } ),
        [ 'cmd', '-a', '' ],
        q[short string '']
    );


    is_deeply( prep_cmd( 'cmd', { long => true } ),
        [qw( cmd --long )], q[long bool true] );

};


# test if conversion from _ to - works

subtest 'underbars' => sub {

    is_deeply( prep_cmd( 'cmd', { under_bar => true } ),
        [qw( cmd --under-bar )], q[long under_bar true] );

    is_deeply( prep_cmd( 'cmd', { und_er_bar => true } ),
        [qw( cmd --und-er-bar )], q[long und_er_bar true] );

    is_deeply( prep_cmd( 'cmd', { und__bar => true } ),
        [qw( cmd --und--bar )], q[long und__bar true] );

};


# test repeated attribute values

subtest 'repeated attributes' => sub {

    is_deeply( prep_cmd( 'cmd', { a => [ 1, 2 ] } ),
        [qw( cmd -a 1 -a 2 )], q[scalar, scalar] );

    is_deeply( prep_cmd( 'cmd', { a => [ 1, true ] } ),
        [qw( cmd -a 1 -a 1 )], q[scalar, true] );

    is_deeply( prep_cmd( 'cmd', { a => [ 1, false ] } ),
        [qw( cmd -a 1 -a 0 )], q[scalar, false] );

    is_deeply( prep_cmd( 'cmd', { a => [ 1, undef ] } ),
        [qw( cmd -a 1 )], q[scalar, undef (ignored)] );

};

is_deeply( prep_cmd( 'cmd', [ qw( a b c ) ] ),
	   [ qw( cmd a b c ) ],
	   'positional args only' );

is_deeply( prep_cmd( 'cmd', [ qw( a b c ) ], { a => [ 1, 2 ] } ),
	   [ qw( cmd -a 1 -a 2 a b c ) ],
	   'mixed positional and opts' );

# ignore undef in positional args
is_deeply( prep_cmd( 'cmd', [ undef ], { a => [1, 2 ] } ),
	   [ qw( cmd -a 1 -a 2 ) ],
	   'ignore undef in positional args' );

done_testing;

#!perl

use strict;
use warnings;

use t::common;

use Test::More;
use Test::Fatal;
use Test::Roo;

use Hg::Lib;
use Hg::Lib::Exception -aliases;

with 'Test::Hg::Lib::Role::TempDir';

test 'no repo' => sub {

    my $e = exception{ Hg::Lib->open( connect => 1, hg => hg ) };

    isa_ok( $e, ENoRepo, 'connect' );
};

test 'repo, nopath' => sub {

    create_repo;

    my $e = exception{ Hg::Lib->open( connect => 1, hg => hg ) };

    is( $e, undef, 'connect' );
};

test 'repo, path' => sub {

    create_repo( 'subdir' );

    my $e = exception{ Hg::Lib->open( connect => 1, hg => hg,
				      path => 'subdir' ) };

    is( $e, undef, 'connect' );
};

test 'encoding' => sub {

    my $hg;

    # need to use fake hg 'cause Foo isn't a legit encoding
    my $e = exception{ $hg = Hg::Lib->open( connect => 1,
					    hg => fake_hg,
					    encoding => 'Foo',
					    args => 'basic',
					  ) };

    is( $e, undef, 'connect' );

    if ( defined $hg ) {
	is( $hg->getencoding, 'Foo', 'correct encoding' );
    }

    else {
	diag( "bailing" );
    }

};

run_me;
done_testing;

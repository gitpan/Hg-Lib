#!perl

use strict;
use warnings;

use t::common;

use Test::Roo;
use Test::Fatal;

use Hg::Lib::Server;
use Hg::Lib::Exception -aliases;

with 'Test::Hg::Lib::Role::TempDir';

test 'no repo'=> sub {

    my $e = exception{ Hg::Lib::Server->new( connect => 1, hg => hg ) };

    isa_ok( $e, ENoRepo, 'no repo' );

};

test 'repo, no path' => sub {

    create_repo;

    my $e = exception{ Hg::Lib::Server->new( connect => 1, hg => hg ) };

    is( $e, undef, 'repo, no path' );
};

test 'repo, path' => sub {

    create_repo( 'subdir' );

    my $e = exception{ Hg::Lib::Server->new( connect => 1, hg => hg,
					   path => 'subdir' ) };

    is( $e, undef, 'repo, path' );
};

run_me;
done_testing;

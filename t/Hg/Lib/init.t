#!perl

use strict;
use warnings;

use t::common;

use Test::File;
use Test::Fatal;
use Test::Roo;

with 'Test::Hg::Lib::Role::TempDir';

use Hg::Lib;
use Hg::Lib::Exception -aliases;

test 'current dir' => sub {

    is( exception{ Hg::Lib->init( ) },
	undef,
	'create repo in current dir',
      );

    dir_exists_ok( '.hg', "hg repo subdir" );
};

test 'path' => sub {

    is ( exception{ Hg::Lib->init( dest => 'subdir' ) },
	 undef,
	 'create repo in specified path'
       );

    dir_exists_ok( 'subdir/.hg', "hg repo subdir" );

};


run_me;
done_testing;

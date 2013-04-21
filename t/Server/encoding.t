#!perl

use strict;
use warnings;

use t::common;

use Test::More;

use Hg::Lib::Server;

sub new { Hg::Lib::Server->new( hg => fake_hg, @_ ) }

is( new( args => 'basic' )->getencoding, 'utf-8', 'default encoding' );

done_testing;



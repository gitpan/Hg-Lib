#! perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Type::Params qw[ validate ];
use Hg::Lib::Types -all;

is_deeply (
	   validate( [ ['a'] ], StrList ),
	   [ 'a' ],
	    'StrList as arrayref'
);

is_deeply (
	   validate( [ 'a' ], StrList ),
	   [ 'a' ],
	   'StrList as scalar'
);

isa_ok( exception { StrList->assert_valid( \'a' ) },
	'Type::Exception::Assertion'
      );

done_testing;

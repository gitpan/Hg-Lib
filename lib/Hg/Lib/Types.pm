package Hg::Lib::Types;

use feature 'state';

use Type::Library
  -base,
  -declare => qw[
  StrList
  RunCommandErrorHandler
];

use Type::Utils;
use Types::Standard qw[ ArrayRef Str Undef CodeRef Enum ];

declare StrList,
  as ArrayRef [Str];

coerce StrList, from Str, '[ $_ ]', from Undef, '[]',;

declare RunCommandErrorHandler, as CodeRef;

coerce RunCommandErrorHandler, from Enum( [qw< throw return >] ), via {
    require Hg::Lib::Exception;

    state $throw = sub {
        sub {
            Hg::Lib::Exception::Command->throw( result => shift );
          }
    };

    state $return = sub {
        sub {
            return shift;
          }
    };

    return $_ eq 'throw' ? $throw : $return;
};

1;


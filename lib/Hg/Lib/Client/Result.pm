package Hg::Lib::Client::Result;

use Moo;

use Hg::Lib::Types qw[ StrList ];
use Types::Standard qw[ Int Str Maybe ];

use overload
  'bool' => \&ret_ok,
  '""'   => \&stringify;

has cmd => (
    is       => 'ro',
    isa      => StrList,
    required => 1,
);

has ret => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has output => (
    is       => 'ro',
    isa      => Maybe[Str],
    required => 1,
);

has error => (
    is       => 'ro',
    isa      => Maybe[Str],
    required => 1,
);

sub ret_ok { $_[0]->ret == 0 }

sub stringify {

    my $self = shift;

    sprintf( qq[command "%s" exited with "%d": %s],
            join( ' ', @{$self->cmd}),  $self->ret, $self->error );

}

1;


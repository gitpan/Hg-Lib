#! perl

package Test::Hg::Lib::Role::Client;

use File::Spec::Functions qw[ curdir ];

use Moo::Role;

use Hg::Lib;

has dir => (
    is        => 'ro',
    default   => curdir,
);

has client => (
    is      => 'lazy',
    init_args => undef,
    clearer => 1,
);

sub _build_client { Hg::Lib::init( shift->dir ) }

before each_test => sub {

    $_[0]->client;
};

after each_test => sub {

    $_[0]->clear_client;

};


1;


package Test::Hg::Lib::Role::TempDir;

use Moo::Role;

use File::pushd ();

has tempdir => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => 1,
);

# create new tempdir before each test

sub _build_tempdir {

    File::pushd::tempd();

}

before each_test => sub {

    shift->tempdir;

};

after each_test => sub {

    shift->clear_tempdir;

};

1;

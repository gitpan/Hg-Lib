#! perl

package Test::Hg::Lib::Role::BasicRepo;

use Test::Directory;
use File::pushd;

use Moo::Role;

has repo_dir => (
    is        => 'lazy',
    init_args => undef,
    clearer   => 1,

);

has _dir_lock => (

    is        => 'lazy',
    init_args => undef,
    default   => sub { pushd( shift->repo_dir->path ) },
    clearer   => 1,

);

sub _build_repo_dir {

    my $self = shift;

    my $tdir = Test::Directory->new;

    for my $file ( qw[ a b c ] ) {
        $tdir->create( $file, content => $file );
    }

    return $tdir;

}


before each_test => sub {

    $_[0]->repo_dir;
    $_[0]->_dir_lock;
};

after each_test => sub {

    $_[0]->clear_repo_dir;
    $_[0]->_clear_dir_lock;

};

1;


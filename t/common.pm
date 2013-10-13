package t::common;

use parent Exporter;

use Cwd 'getcwd';

our @EXPORT = ( qw[ fake_hg hg create_repo ] );

use Probe::Perl;
use File::Which;
use File::Spec::Functions qw[ catdir catfile ];
use Capture::Tiny qw[ capture ];

use Test::Builder;

my $perl;

BEGIN {
    use lib catdir( getcwd(), 't', 'lib');

    $perl = Probe::Perl->find_perl_interpreter
	or die( "unable to locate Perl interpreter\n" );
}

INIT {
    use constant fake_hg => [ $perl, catfile( getcwd(), 't', 'fake-hg' ) ];
    use constant hg => scalar which('hg');
}

sub run_hg {

    $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $message, @args ) = @_;

    my ( $stdout, $stderr, $exit ) = capture {
	system( hg, @args )
    };

    Test::Builder->new->is_num( $exit, 0, $message );
}

sub create_repo {

    run_hg( 'create repo' => 'init', @_ ) ;

}


1;

package Test::Hg::Lib::Exec;

use strict;
use warnings;


use base 'Exporter';
our @EXPORT = ( qw[ xhg ] );

use Capture::Tiny 'capture';
use t::common;

sub _hg {

    my  @args = @_;

    my ( $out, $err, $exit ) =  capture { system( hg, @args )  };

    die( "error running '", join( ' ', hg, @args ), "' ($exit): \n$err" )
      if $exit;

    return $out;
}

sub xhg {

    my $cmd = shift;

    no strict 'refs';
    $cmd->( @_ );

}


sub status {

    my $out = _hg( status => @_ );

    my %status;
    while( $out =~ /^(?<code>.)\s(?<file>.*)$/mg ) {
	$status{$+{file}} = $+{code};
    }

    return \%status;
}

1;


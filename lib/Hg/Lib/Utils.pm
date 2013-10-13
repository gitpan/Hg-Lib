package Hg::Lib::Utils;

use boolean ':all';

use base 'Exporter';
our @EXPORT_OK = ( qw[ prep_cmd find_hg ] );

# prep commands for submission to server
# prep_cmd( $cmd, \@pos, \%named )
# prep_cmd( $cmd, \@pos )
# prep_cmd( $cmd, \%named )

sub prep_cmd {

    my @cmd  = ( shift );
    my $pos  = 'ARRAY' eq ref $_[0] ? shift : [];
    my $opts = 'HASH' eq ref $_[-1] ? shift : {};

    while ( my ( $k, $v ) = each %$opts ) {

        $k =~ s/_/-/g;

        $k = ( length( $k ) > 1 ? '--' : '-' ) . $k;

        if ( isFalse( $v ) ) {

        }

        elsif ( isTrue( $v ) ) {

            push @cmd, $k;

        }

        else {

            $v = [$v] unless 'ARRAY' eq ref $v;

            push @cmd, $k, $_ foreach grep { defined } @$v;
        }

    }

    push @cmd, grep { defined } @$pos;

    return \@cmd;
}

sub find_hg {

    require File::Which;

    return scalar File::Which::which( 'hg' );

}

1;

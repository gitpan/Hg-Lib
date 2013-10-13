# Exception classes

package Hg::Lib::Exception;

use strict;
use warnings;

# Create the exception hierarchy and aliases for them

use parent 'Exporter::Tiny';
our @EXPORT;
our @EXPORT_OK;
our %EXPORT_TAGS = ( 'aliases' => \@EXPORT_OK );

my @Exceptions = (
    # Exception                => Alias
    'Internal'                 => ['EInternal'],
    'Server'                   => [],
    'Server::Handshake'        => ['EHandshake'],
    'Server::NoRepo'           => ['ENoRepo'],
    'Server::Capability'       => ['ECapability'],
    'Server::Encoding'         => ['EEncoding'],
    'Server::Pipe'             => ['EPipe'],
    'Server::Pipe::EOF'        => ['EPipeEOF'],
    'Server::Pipe::Stderr'     => ['EPipeStderr'],
    'Server::Pipe::Terminated' => ['EPipeTerminated'],
    'Server::Pipe::Timeout'    => ['EPipeTimeout'],
);

mk_exception( splice( @Exceptions, 0, 2 ) ) while @Exceptions;

sub mk_exception {

    my ( $exception, $aliases ) = @_;

    my ( $parent ) = $exception =~ /(?:(.*)::)?.*/;

    $parent = join( '::', __PACKAGE__, ( $parent // () ) );
    $exception = join( '::', __PACKAGE__, $exception );

    no strict 'refs';
    push @{"$exception\::ISA"}, $parent;

    for my $alias ( @$aliases ) {
        # no closures, please
        *{ __PACKAGE__ . "::$alias" } = eval qq[sub () { '$exception' }];
        push @EXPORT_OK, $alias;
    }

}

#--------------------------------
# now create the base class

use Moo;

with 'Throwable';

has text => ( is => 'ro', required => 1 );

use overload '""' => 'stringify';

sub BUILDARGS {
    shift;
    unshift @_, 'text' if @_ % 2;
    return {@_};
}

sub stringify {

    my $self = shift;

    my $s;
    return join( "\n",
        $self->text, ( defined( $s = $self->previous_exception ) ? $s : () ) );
}

# special sub classes

package Hg::Lib::Exception::Command;

use Moo;

use Types::Standard qw[ InstanceOf ];

extends 'Hg::Lib::Exception';

has '+text' => (
    required => 0,
    lazy     => 1,
    default  => sub { shift->result->stringify },
);

has result => ( is => 'ro',
		isa =>  InstanceOf[ 'Hg::Lib::Client::Result' ],
		required => 1 );

Hg::Lib::Exception::mk_exception( Command => ['ECommand'] );

1;

__END__

=pod

=head1 NAME

Hg::Lib::Exception

=head1 VERSION

version 0.01_05

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Diab Jerius E<lt>djerius@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

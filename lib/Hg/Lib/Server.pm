package Hg::Lib::Server;

use 5.10.1;

use Carp;

# for perl 5.10.1
use FileHandle;

use Moo;

with 'MooX::Attributes::Shadow::Role';

use Hg::Lib::Exception -aliases;

use Hg::Lib::Server::Pipe;

Hg::Lib::Server::Pipe->shadow_attrs;

shadowable_attrs( keys %{ Hg::Lib::Server::Pipe->shadowed_attrs }, 'connect' );

has connect => (
    is      => 'ro',
    default => 0,
);

has server => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    handles  => [
        qw[ get_chunk write writeblock getencoding runcommand close ]
    ],
    default   => sub { Hg::Lib::Server::Pipe->new_from_attrs( $_[0] ) },
    predicate => 1,
    clearer   => 1,
);

sub BUILD {

    my $self = shift;

    $self->server if $self->connect;
}

sub DEMOLISH {

    my $self = shift;

    local $@;
    eval { $self->server->close }
      if $self->has_server;

    EPipe->throw( "error closing down server" )
      if $@;
}

1;

__END__

=pod

=head1 NAME

Hg::Lib::Server

=head1 VERSION

version 0.01_05

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Diab Jerius E<lt>djerius@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

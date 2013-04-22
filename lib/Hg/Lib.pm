use strict;
use warnings;
package Hg::Lib;

# ABSTRACT: Interface to mercurial's command server

use 5.10.1;

our $VERSION = '0.01_03';

1;

__END__

=pod

=head1 NAME

Hg::Lib - Interface to mercurial's command server

=head1 VERSION

version 0.01_03

=head1 SYNOPSIS

  use HG::Lib;

  my $server = HG::Lib->new( );

=head1 DESCRIPTION

B<mercurial> is a distributed source control management
tool. B<Hg::Lib> is an interface to its command server.

B<THIS CODE IS ALPHA QUALITY.> This code is incomplete.  Interfaces may change.

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Diab Jerius E<lt>djerius@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

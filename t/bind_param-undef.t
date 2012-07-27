# Test bind of values 0, '0', "", and undef

# $Id: bind_param-undef.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking
use Test::More;        # advanced testing

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;                 # what we are testing

plan tests => 6;

# ------ define variables
my $dbh        = undef;    # mock DBI database handle
my $md         = undef;    # Test::MockDBI instance

$md	= Test::MockDBI::get_instance();
isa_ok($md, q{Test::MockDBI}, q{Expect a Test::MockDBI reference});

$dbh = DBI->connect("universe", "mortal", "root-password");
isa_ok($dbh, q{DBI::db}, q{Expect a DBI::db reference});
  
is($dbh->bind_param(1, "dan", { "horse" => "big" }), 1, q{Expect hash param to work});
is($dbh->bind_param(2, "sugar", "small"), 1, q{Expect scalar param to work});
is($dbh->bind_param(3, "molly"), 1, q{Expect undef value to work});

is($dbh->disconnect(), 1, q{Expect 1});

__END__


=pod

=head1 TODO

This test only check that bind_param works. Additionally, it should
check more thoroughly that they get set correctly. However, that would
require a I<get_bind_params> or similar routine in MockDBI.pm.

=cut 

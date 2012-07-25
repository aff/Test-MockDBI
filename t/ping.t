# Test DBI::ping

# $Id: ping.t 278 2008-12-31 13:33:34Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=3"; }

# ------ use/require pragmas
use strict;      # better compile-time checking
use warnings;    # better run-time checking

use Test::More tests => 1;    # advanced testing
use File::Spec::Functions;
use lib catdir qw ( blib lib );               # use local module
use Test::MockDBI qw ( :all );    # what we are testing

# ------ define variables
my $dbh      = "";                              # mock DBI database handle
my $md       = Test::MockDBI::get_instance();

# ------ set_retval_scalar wildcard DBI type
$dbh = DBI->connect();
is($dbh->ping, 1, q{Check ping});

__END__ 

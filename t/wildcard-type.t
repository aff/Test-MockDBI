# Test::MockDBI wildcard DBI type

# $Id: wildcard-type.t 247 2008-12-04 13:01:43Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=3"; }

# ------ use/require pragmas
use strict;      # better compile-time checking
use warnings;    # better run-time checking

use Test::More tests => 2;    # advanced testing
use File::Spec::Functions;
use lib catdir qw ( blib lib );               # use local module
use Test::MockDBI qw ( :all );    # what we are testing

# ------ define variables
my @array    = ();                              # generic array
my $arrayref = "";                              # generic arrayref
my $dbh      = "";                              # mock DBI database handle
my $md       = Test::MockDBI::get_instance();
my $test_sql = "SELECT ALL";


# ------ set up return value based on wildcard DBI testing type
$md->set_retval_scalar(Test::MockDBI::MOCKDBI_WILDCARD, $test_sql, [ 42 ]);
$md->set_retval_array(                MOCKDBI_WILDCARD, $test_sql, 1054, 1066);


# ------ set_retval_scalar wildcard DBI type
$dbh = DBI->connect();
$dbh->prepare($test_sql);
$arrayref = $dbh->fetchrow_arrayref();
is($arrayref->[0], 42,
 "set_retval_scalar wildcard DBI type");


# ------ set_retval_array wildcard DBI type
@array = $dbh->fetchrow_array();
ok(scalar(@array) == 2 && $array[0] == 1054 && $array[1] == 1066,
 "set_retval_array wildcard DBI type");

__END__ 

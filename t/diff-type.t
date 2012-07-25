# Test::MockDBI different DBI type  than requested

# $Id: diff-type.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=3"; }

# ------ use/require pragmas
use strict;				# better compile-time checking
use warnings;				# better run-time checking
use Test::More tests =>  3;		# advanced testing
use File::Spec::Functions;
use lib catdir qw ( blib lib );			# use local module
use Test::MockDBI;			# what we are testing


# ------ define variables
my @array = ();				# generic array
my $dbh = "";				# mock DBI database handle
my $md					# Test::MockDBI instance
 = Test::MockDBI::get_instance();
my $test_sql				# test SQL
 = "SELECT *";


# ------ try to influence DBI method behavior but use different DBI type
$md->bad_method(       "connect", 2, "CONNECT");
$md->set_retval_scalar($test_sql, 2, [ 42 ]);
$md->set_retval_array( $test_sql, 2, 42, 476);


# ------ bad_method() fails on different DBI type
is(ref($dbh = DBI->connect()), "DBI::db",
 "bad_method() fails on different DBI type");


# ------ set_retval_scalar fails on different DBI type
$dbh->prepare($test_sql);
is($dbh->fetchrow_arrayref(), undef,
 "set_retval_scalar fails on different DBI type");

# ------ set_retval_array fails on different DBI type
$dbh->prepare($test_sql);
@array = $dbh->fetchrow_array();
is($array[0], undef,
 "set_retval_array fails on different DBI type");

__END__

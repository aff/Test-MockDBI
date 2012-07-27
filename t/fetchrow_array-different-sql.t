# Test::MockDBI fetch*() which return an array handle multiple SQL statements.

# $Id: fetchrow_array-different-sql.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking

use Test::More;

plan tests => 5;

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;     # what we are testing

# ------ define variables
my $dbh = "";          # mock DBI database handle
my $md = Test::MockDBI::get_instance();
my @retval = ();       # return value from fetchrow_array()


# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");
$md->set_retval_array(2, "FETCHROW_ARRAY", "go deep", 476);
$md->set_retval_array(2, "SELECT zip5_zipcode.+'Chino Hills'",
 "Experian stuff", 1492);

# test non-matching sql
$dbh->prepare("other SQL");
ok(!defined($dbh->fetchrow_array()), q{Expect undef on non-matching sql});
$dbh->finish();

# test matching sql
$dbh->prepare("FETCHROW_ARRAY");
@retval = $dbh->fetchrow_array();
is_deeply(\@retval, [ "go deep", 476 ]);
$dbh->finish();

# test non-matching sql again
$dbh->prepare("STILL oTheR SQL");
ok(!defined($dbh->fetchrow_array()), q{Expect undef on another non-matching sql});
$dbh->finish();

# test another matching sql
$dbh->prepare("SELECT zip5_zipcode FROM ziplist5 WHERE zip5_cityname = 'Chino Hills'");
@retval = $dbh->fetchrow_array();
is_deeply(\@retval, ["Experian stuff", 1492], q{Expect array ("Experian stuff", 1492)});
$dbh->finish();

# test non-matching sql third time
$dbh->prepare("LaSt sqL");
ok(!defined($dbh->fetchrow_array()), q{Expect undef on another non-matching sql});

__END__

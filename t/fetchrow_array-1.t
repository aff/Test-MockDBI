# Test::MockDBI fetchrow_array() with 1-element array returned

# $Id: fetchrow_array-1.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking

use Test::More;        # advanced testing

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;     # module we are testing

plan tests => 6;


# ------ define variables
my $dbh    = "";                            # mock DBI database handle
my $md     = Test::MockDBI::get_instance();
my @retval = ();                            # return array from fetchrow_array()


# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");
$md->set_retval_array(2, "FETCHROW_ARRAY", 42); 

# test non-matching sql
$dbh->prepare("other SQL");  
@retval = $dbh->fetchrow_array();
cmp_ok(scalar(@retval), q{==}, 0, q{Expect 0 columns});
$dbh->finish();

# test matching sql
$dbh->prepare("FETCHROW_ARRAY");  
@retval = $dbh->fetchrow_array();
cmp_ok(scalar(@retval), q{==}, 1, q{Expect 1 column in row});
cmp_ok($retval[0], q{==}, 42, q{Expect 1st column in row to contain 42});

$dbh->finish();


# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");
$md->set_retval_array(2, "fetch hash ref", {'test' => 2}); # return nothing (3rd arg) 

# test hash as first element
$dbh->prepare("fetch hash ref");  
@retval = $dbh->fetchrow_array();
cmp_ok(scalar(@retval), q{==}, 1, q{Expect 1 hash in row});
$dbh->finish();

# ------ set up return values for select methods
$dbh = DBI->connect("", "", "", { AutoCommit => 0 });
$md->set_retval_array(2, "select AutoCommit as 0", [123]); # return nothing (3rd arg) 

# test hash as first element
$dbh->prepare("select AutoCommit as 0");  
@retval = $dbh->fetchrow_array();
cmp_ok(scalar(@retval), q{==}, 1, q{Expect 1 scalar in row});
$dbh->finish();

# ------ set up return values for insert methods
$dbh = DBI->connect("", "", "", { AutoCommit => 0 });
$md->set_retval_array(2, "insert AutoCommit as 0", [123]); # return nothing (3rd arg) 

# test hash as first element
$dbh->prepare("insert AutoCommit as 0");  
@retval = $dbh->fetchrow_array();
cmp_ok(scalar(@retval), q{==}, 1, q{Expect 1 null in row});
$dbh->finish();


__END__

=pod

=cut

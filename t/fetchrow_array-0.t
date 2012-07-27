# Test::MockDBI fetchrow_array() when given no array to return

# $Id: fetchrow_array-0.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking

use Test::More;        # advanced testing

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;     # module we are testing

plan tests => 3;


# ------ define variables
my $dbh    = "";                            # mock DBI database handle
my $md     = Test::MockDBI::get_instance();
my @retval = ();                            # return array from fetchrow_array()


# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");
#When no values are set 
@retval = $dbh->fetchrow_array();
cmp_ok(scalar(@retval), q{==}, 0, q{Expect 0});

$md->set_retval_array(2, "FETCHROW_ARRAY"); # return nothing (3rd arg) 

# test non-matching sql
$dbh->prepare("other SQL");  
@retval = $dbh->fetchrow_array();
cmp_ok(scalar(@retval), q{==}, 0, q{Expect 0});
$dbh->finish();

# test matching sql
$dbh->prepare("FETCHROW_ARRAY");  
@retval = $dbh->fetchrow_array();
cmp_ok(scalar(@retval), q{==}, 0, q{Expect 0});
$dbh->finish();



__END__

=pod

=cut

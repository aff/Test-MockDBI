# Test::MockDBI fetch() when given no array to return

# $Id: fetch-empty.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking

use Test::More;        # advanced testing

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;     # module we are testing

plan tests => 2;


# ------ define variables
my $dbh    = "";                            # mock DBI database handle
my $md     = Test::MockDBI::get_instance();
my @retval = ();                            # return array from fetch()


# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");
$md->set_retval_array(2, "FETCH");

# test non-matching sql
$dbh->prepare("other SQL");  
@retval = $dbh->fetch();
cmp_ok(scalar(@retval), q{==}, 0, q{Expect 0 columns for non-matching sql});
$dbh->finish();

# test matching sql
$dbh->prepare("FETCH");  
@retval = $dbh->fetch();
cmp_ok(scalar(@retval), q{==}, 0, q{Expect 0 columns for matching sql});

$dbh->finish();

__END__

=pod

=cut

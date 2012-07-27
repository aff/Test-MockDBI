# Test::MockDBI fetchrow() with many-element array returned
# (For our purposes, 2 eq many.)

# $Id: fetchrow-many.t 246 2008-12-04 13:01:22Z aff $

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
my @retval = ();                            # return array from fetchrow()


# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");
$md->set_retval_array(2, "FETCHROW", "go deep", 476);

# test non-matching sql
$dbh->prepare("other SQL");  
ok(!defined($dbh->fetchrow()), q{Expect 0 columns});
$dbh->finish();

# test matching sql
$dbh->prepare("FETCHROW");  
@retval = $dbh->fetchrow();
ok(scalar(@retval) == 2, q{Expect 2 columns per row});
is_deeply( \@retval, [ "go deep", 476 ], q{Expect 1st row to contain [ "go deep", 476 ]});

$dbh->finish();

__END__

=pod

=cut

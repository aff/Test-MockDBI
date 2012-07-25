# Test::MockDBI fetchrow() with 1-element array returned

# $Id: $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=1"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking

use Test::More;        # advanced testing

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;     # module we are testing

plan tests => 4;


# ------ define variables
my $dbh = undef;                           # mock DBI database handle
my $md  = Test::MockDBI::get_instance();
my $retval = undef;    # return array from fetchrow()


# ------ set up return values rows methods
$dbh = DBI->connect("", "", "");
$md->set_rows(1, "FETCHROW", 1016);

# test non-matching sql
$dbh->prepare("FETCHROW");  
ok(defined($dbh->rows()), q{Expect row to be set from set_rows});


$dbh->finish();

# ------ set up no values for rows methods
$dbh = DBI->connect("", "", "");
$md->set_rows(1, "fetchrow_notset");

# test non-matching sql
$dbh->prepare("fetchrow_notset");  
ok(!defined($dbh->rows()), q{Expect row not to be set from set_rows});


$dbh->finish();

# ------ set up return values for  select methods
$dbh = DBI->connect("", "", "");
$md->set_rows(1, "select", 1016);

# test non-matching sql
$dbh->prepare("select");  
ok(defined($dbh->rows()), q{Expect row to be set from set_rows - select});


$dbh->finish();

# ------ set up code as return values for row methods
$dbh = DBI->connect("", "", "");
$md->set_rows(1, "code ref", sub { return "hi"; });

# test non-matching sql
$dbh->prepare("code ref");
ok($dbh->rows() eq 'hi', q{Expect "hi" to be set from set_rows - code ref});


$dbh->finish();

__END__

=pod

=cut

# Test::MockDBI fetchall_arrayref() when given no array to return

# $Id: fetchall_arrayref-0.t 246 2008-12-04 13:01:22Z aff $

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
my $retval = "";			# return value from fetchall_arrayref()


# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");
$md->set_retval_array(2, "FETCHALL_ARRAYREF");

# test non-matching sql
$dbh->prepare("other SQL");  
$retval = $dbh->fetchall_arrayref();
ok(!defined($retval), q{Expect undef for non-matching sql});
$dbh->finish();

# test matching sql
$dbh->prepare("FETCHALL_ARRAYREF");  
$retval = $dbh->fetchall_arrayref();
ok(!defined($retval), q{Expect defined for non-matching sql});

$dbh->finish();

__END__

=pod

=cut

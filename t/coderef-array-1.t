# Test::MockDBI fetch*() with 1-element array returned from coderef

# $Id: coderef-array-1.t 246 2008-12-04 13:01:22Z aff $

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
my @retval = ();                            # return value from fetchrow_array()

# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");
$md->set_retval_array(2, "FETCHROW_ARRAY",  sub { return 1054;});

# test non-matching sql
$dbh->prepare("other SQL");  
ok(!defined($dbh->fetchrow_array()), q{Expect undef for non-matching sql});
$dbh->finish();

# test matching sql
$dbh->prepare("FETCHROW_ARRAY");  
@retval = $dbh->fetchrow_array();
is_deeply(\@retval, [ 1054 ], q{Expect array with element 1054});
$dbh->finish();


__END__

=pod

=cut

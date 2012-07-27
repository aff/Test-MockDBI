# Test::MockDBI fetch*() with many-element array returned from coderef

# $Id: coderef-scalar-many.t 246 2008-12-04 13:01:22Z aff $

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
my $dbh    = "";                              # mock DBI database handle
my $md     = Test::MockDBI::get_instance();
my $retval = undef;

# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");
$md->set_retval_scalar(2, "FETCHROW",  sub { return [ 1016, 1066 ]; });

# test non-matching sql
$dbh->prepare("other SQL");  
$retval = $dbh->fetchrow_arrayref();
ok(!defined($retval), q{Expect 0 columns});
$dbh->finish();

# test matching sql
$dbh->prepare("FETCHROW");  
$retval = $dbh->fetchrow_arrayref();
ok(defined($retval), q{Expect defined for matching sql});
is_deeply($retval, [ 1016, 1066 ], q{Expect 2 element array [ 1016, 1066 ]});

$dbh->finish();


__END__

=pod

=cut

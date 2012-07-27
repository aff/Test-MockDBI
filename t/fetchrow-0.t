# Test::MockDBI fetchrow() when given no array to return

# $Id: fetchrow-0.t 246 2008-12-04 13:01:22Z aff $

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
my $dbh = undef;                           # mock DBI database handle
my $md  = Test::MockDBI::get_instance();
my $retval = undef;    # return array from fetchrow()


# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");
$md->set_retval_array(2, "FETCHROW"); # return nothing (3rd arg) 

# test non-matching sql
$dbh->prepare("other SQL");  
ok(!defined($dbh->fetchrow()), q{Expect undef with non-matching sql from fetchrow});
$dbh->finish();

# test matching sql
$dbh->prepare("FETCHROW");  
($retval) = $dbh->fetchrow();
ok(!defined($retval), q{Expect undef with matching sql from fetchrow});
$dbh->finish();

__END__

=pod

=cut

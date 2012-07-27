# $Id: fetchrow_hashref-0.t 236 2008-12-04 10:28:12Z aff $

use strict;				
use warnings;				

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }

use Data::Dumper;
use Test::More;

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local version of Test::MockDBI
use Test::MockDBI;			

plan tests => 2;

# ------ define variables
my $dbh = "";                                      # mock DBI database handle
my $md  = Test::MockDBI::get_instance();
my $hashref = undef;

# ------ set up return values for DBI fetchrow_hashref() methods
$dbh = DBI->connect("", "", "");
$md->set_retval_array(2, "FETCHROW_HASHREF");

# non-matching sql
$dbh->prepare("other SQL");
$hashref = $dbh->fetchrow_hashref();
ok(!defined($hashref), q{Expect fetchrow_hashref to return undefined value for non-matching sql});
$dbh->finish();

# matching sql
$dbh->prepare("FETCHROW_HASHREF");
$hashref = $dbh->fetchrow_hashref();
ok(!defined($hashref), q{Expect fetchrow_hashref to return undefined value for matching sql});
$dbh->finish();



__END__


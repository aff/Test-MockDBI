# Test making DBI parameters bad

# $Id: bad_param-1.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking
use Test::More;        # advanced testing
use Data::Dumper;
use Test::Warn;

use File::Spec::Functions;
#use lib "/home/santosh_shet/svn/smm/smm/trunk/lib/Shared/Test-MockDBI-0.65/lib";    # use local module
use lib catdir qw ( blib lib );
use Test::MockDBI;     # what we are testing

plan tests => 10;

# ------ define variables
my $dbh        = undef;    # mock DBI database handle
my $md         = undef;    # Test::MockDBI instance
my @retval     = ();       # return array from fetchrow_array()
my $select     = undef;    # DBI SQL SELECT statement handle

# ------ set up return values for DBI fetch*() methods
$md	= Test::MockDBI::get_instance(1);
isa_ok($md, q{Test::MockDBI}, q{Expect a Test::MockDBI reference});

# Set 1st param bad (In mode --dbitest=2)
like($md->bad_param(2, 1, "jimbo"), qr/^\d+$/, q{Expect a positive integer (bad_param))});
like($md->set_retval_scalar(2, "SOmE SQL", [42]),
  qr/^\d+$/, q{Expect a positive integer (set_retval_scalar))});

# Connect and prepare
$dbh = DBI->connect("", "", "");
isa_ok($dbh, q{DBI::db}, q{Expect a DBI::db reference});
$select = $dbh->prepare("SOmE SQL"),
isa_ok($select, q{DBI::db}, q{Expect a DBI::db reference});

# Verify that param is bad
is($md->_is_bad_param(2,1,q{jimbo}), 1, q{Expect 1st param to be bad if the value is 'jimbo' in mode 2});

# Bind, execute and fetch

my $warn = qr/DBI::db bind_param failed/;
warnings_like { $select->bind_param(1, "jimbo", {test => "hi"}) } $warn, "Expect warning like DBI::db bind_param failed: SQL0100 MOCK_DBI: BAD PARAM 1 = 'jimbo'. SQLSTATE=02000";

is($select->execute(), 1, q{Expect 1 (execute 1))});

ok(!defined($select->fetchrow_arrayref()), q{Expect non-match since param is bad});
is($select->finish(), 1, q{Expect 1 (finish) });

__END__

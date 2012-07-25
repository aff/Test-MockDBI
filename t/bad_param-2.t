# Test making DBI parameters bad

# $Id: bad_param-2.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking
use Test::More;        # advanced testing
use Data::Dumper;
use Test::Warn;

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;     # what we are testing

plan tests => 12;

# ------ define variables
my $dbh        = undef;    # mock DBI database handle
my $md         = undef;    # Test::MockDBI instance
my @retval     = ();       # return array from fetchrow_array()
my $select     = undef;    # DBI SQL SELECT statement handle

$md	= Test::MockDBI::get_instance(1);
isa_ok($md, q{Test::MockDBI}, q{Expect a Test::MockDBI reference});

# Set 2nd param bad (In mode --dbitest=2)
like($md->bad_param(2, 2, "noblesville"),
  qr/^\d+$/, q{Expect a positive integer (bad_param))});
like($md->set_retval_scalar(2, "other SQL", [42]),
  qr/^\d+$/, q{Expect a positive integer (set_retval_scalar))});

# Connect and prepare
$dbh = DBI->connect("", "", "");
isa_ok($dbh, q{DBI::db}, q{Expect a DBI::db reference});
$select = $dbh->prepare("other SQL");
isa_ok($select, q{DBI::db}, q{Expect a DBI::db reference});

# Verify that '46062' param is good
ok(!defined($md->_is_bad_param(2,1,q{46062})), q{Expect 1st param to be good (regardless of value)in mode 2});

# Verify that 'noblesville' param is bad
is($md->_is_bad_param(2,2,q{noblesville}), 1, q{Expect 2nd param to be bad if the value is 'noblesville' in mode 2});

# Bind, execute and fetch
is($select->bind_param(1, "46062"), 1, q{Expect 1 (bind_param 1))});


my $warn = qr/DBI::db bind_param failed/;
warnings_like { $select->bind_param(2, "noblesville",20) } $warn, "Expect warning like DBI::db bind_param failed: SQL0100 MOCK_DBI: BAD PARAM 2 = 'noblesville'. SQLSTATE=02000";


is($select->execute(), 1, q{Expect 1 (execute 1))});
ok(!defined($select->fetchrow_arrayref()), q{Expect non-match since param is bad});

is($select->finish(), 1, q{Expect 1 (finish) });

__END__



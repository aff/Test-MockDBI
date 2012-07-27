# Test making DBI parameters bad

# $Id: bad_param-diff-type.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=3"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking
use Test::More;        # advanced testing
use Data::Dumper;


use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;     # what we are testing

plan tests => 11;

# ------ define variables
my $dbh        = undef;    # mock DBI database handle
my $md         = undef;    # Test::MockDBI instance
my @retval     = ();       # return array from fetchrow_array()
my $select     = undef;    # DBI SQL SELECT statement handle

$md	= Test::MockDBI::get_instance();
isa_ok($md, q{Test::MockDBI}, q{Expect a Test::MockDBI reference});

# Set param bad in mode 2
like($md->bad_param(2, 1, "jimbo"),
  qr/^\d+$/, q{Set param to be bad in mode 2, expect a positive integer (bad_param))});

# Connect and prepare
$dbh = DBI->connect("", "", "");
isa_ok($dbh, q{DBI::db}, q{Expect a DBI::db reference});
$select = $dbh->prepare("other SQL");
isa_ok($select, q{DBI::db}, q{Expect a DBI::db reference});

like($md->set_retval_scalar(3, "other SQL", [42]),
  qr/^\d+$/, q{Expect a positive integer (set_retval_scalar))});

# Bind, execute and fetch
is($select->bind_param(1, "jimbo"), 1, q{Expect 1 (bind_param 1))});

# Verify that 'jimbo' param is good in mode 3
ok(!defined($md->_is_bad_param(3, 1, q{jimbo})), q{Expect param to be good in mode 3 (scalar context)});

is($select->execute(), 1, q{Expect 1 (execute 1))});
ok(defined($select->fetchrow_arrayref()), q{Expect defined since no params are bad});
cmp_ok($select->fetchrow_arrayref()->[0], q{==}, 42, q{Expect row->[0] == 42 since no params are bad});


is($select->finish(), 1, "finish()");

__END__

=pod

=head1 TEST COMMENT

Setting a param to be bad in mode 3 should not affect queries in mode
2.

=cut

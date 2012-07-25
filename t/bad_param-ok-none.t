# Test making DBI parameters bad

# $Id: bad_param-ok-none.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking
use Test::More;        # advanced testing
use Data::Dumper;


use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;     # what we are testing

plan tests => 16;

# ------ define variables
my $dbh        = undef;    # mock DBI database handle
my $md         = undef;    # Test::MockDBI instance
my @retval     = ();       # return array from fetchrow_array()
my $select     = undef;    # DBI SQL SELECT statement handle

$md	= Test::MockDBI::get_instance();
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
ok(!defined($md->_is_bad_param(2,1,q{46062})), q{Expect param to be good (scalar context)});

# Verify that 'noblesville' param is bad
is($md->_is_bad_param(2,2,q{noblesville}), 1, q{Expect param to be bad (scalar context)});

# Verify that 'Noblesville' param is good
ok(!defined($md->_is_bad_param(2,2,q{Noblesville})), q{Expect param to be good (scalar context)});

# Verify that 'IN' param is good
ok(!defined($md->_is_bad_param(2,3,q{IN})), q{Expect param to be good (scalar context)});

# Bind, execute and fetch
is($select->bind_param(1, "46062"), 1, q{Expect 1 (bind_param 1))});
is($select->bind_param(2, "Noblesville"), 1, q{Expect 1 (bind_param 2 - note case sensitive!))});
is($select->bind_param(3, "IN"), 1, q{Expect 1 (bind_param 3))});

is($select->execute(), 1, q{Expect 1 (execute 1))});
ok(defined($select->fetchrow_arrayref()), q{Expect defined since no params are bad});
cmp_ok($select->fetchrow_arrayref()->[0], q{==}, 42, q{Expect row->[0] == 42 since no params are bad});

is($select->finish(), 1, "finish()");

__END__

=pod

=head1 TEST COMMENT

This checks that setting the param 'noblesville' bad does not affect
the param 'Noblesville'.

=cut

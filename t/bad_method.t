# Test::MockDBI bad DBI method tests

# $Id: bad_method.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }


# ------ use/require pragmas
use strict;      # better compile-time checking
use warnings;    # better run-time checking

use Test::More tests => 34;    # advanced testing
use File::Spec::Functions;
use lib catdir qw ( blib lib );            # use local module
use Test::MockDBI;             # what we are testing
use Test::Warn;

# ------ define variables
my $dbh = "";				# mock DBI database handle
my $md					# Test::MockDBI instance
 = Test::MockDBI::get_instance();


# ------ make all methods bad
is($md->bad_method("connect",           2, "CONNECT"), 1, q{Expect 1});
is($md->bad_method("disconnect",        2, "DISCONNECT"), 1, q{Expect 1});
is($md->bad_method("errstr",            2, ""), 1, q{Expect 1});
is($md->bad_method("prepare",           2, ""), 1, q{Expect 1});
is($md->bad_method("prepare_cached",    2, ""), 1, q{Expect 1});
is($md->bad_method("commit",            2, ""), 1, q{Expect 1});
is($md->bad_method("do",                2, ""), 1, q{Expect 1});
is($md->bad_method("rows",              2, ""), 1, q{Expect 1});
is($md->bad_method("bind_columns",      2, ""), 1, q{Expect 1});
is($md->bad_method("bind_param",        2, ""), 1, q{Expect 1});
is($md->bad_method("execute",           2, ""), 1, q{Expect 1});
is($md->bad_method("finish",            2, ""), 1, q{Expect 1});
is($md->bad_method("fetchall_arrayref", 2, ""), 1, q{Expect 1});
is($md->bad_method("fetchrow_arrayref", 2, ""), 1, q{Expect 1});
is($md->bad_method("fetchrow_array",    2, ""), 1, q{Expect 1});
is($md->bad_method("fetchrow",          2, ""), 1, q{Expect 1});
is($md->bad_method("fetch",             2, "^\$"), 1, q{Expect 1});

# ------ fake DBI object for testing
$dbh = bless {}, "DBI::db";

# ----- NOTE: connect() and disconnect() must be before prepare*()
# -----       as they set the current SQL


# ------ DBI connect()
is(DBI->connect(), undef,
 "DBI connect()");


# ------ DBI disconnect()
is($dbh->disconnect(), undef,
 "DBI disconnect()");


# ------ DBI prepare()
is($dbh->prepare(), undef,
 "DBI prepare()");


# ------ DBI finish()
is($dbh->finish(), undef,
 "DBI finish()");


# ------ DBI prepare_cached()

my $warn = qr/DBI::db prepare_cached failed/;
warnings_like { $dbh->prepare_cached() } $warn, "Expect warning like DBI::db prepare_cached failed";


# ------ DBI commit()
is($dbh->commit(), undef,
 "DBI commit()");


# ------ DBI bind_columns()
my $warnings = qr/DBI::db bind_columns failed/;
warnings_like { $dbh->bind_columns() } $warnings, "Expect warning like DBI::db bind_columns failed";



# ------ DBI bind_param()
is($dbh->bind_param(), undef,
 "DBI bind_param()");


# ------ DBI execute()
is($dbh->execute(), undef,
 "DBI execute()");


# ------ DBI fetchall_arrayref()
is($dbh->fetchall_arrayref(), undef,
 "DBI fetchall_arrayref()");


# ------ DBI fetchrow_arrayref()
is($dbh->fetchrow_arrayref(), undef,
 "DBI fetchrow_arrayref()");


# ------ DBI fetchrow_array()
is($dbh->fetchrow_array(), undef,
 "DBI fetchrow_array()");


# ------ DBI fetchrow()
is($dbh->fetchrow(), undef,
 "DBI fetchrow()");


# ------ DBI fetch()
# ------ also SQL match with explicit pattern but no SQL
is($dbh->fetch(), undef,
 "DBI fetch() + pattern without SQL");


# ------ DBI do()
is($dbh->do(), undef,
 "DBI do()");


# ------ DBI rows()
is($dbh->rows(), undef,
 "DBI rows()");


# ------ SQL without pattern
is(ref($dbh->prepare("SELECT *")), ref($dbh),
 "SQL without pattern");

__END__

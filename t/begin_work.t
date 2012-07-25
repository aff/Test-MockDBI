# DBI connect() for mock DBI.

# $Id: connect.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest"; }

# ------ use/require pragmas
use strict;      # better compile-time checking
use warnings;    # better run-time checking

use Test::More tests => 6;    # advanced testing
use File::Spec::Functions;
use lib catdir qw ( blib lib );           # use local module
use Test::MockDBI;            # what we are testing

# ------ define variables
my $dbh = DBI->connect("universe", "mortal", "root-password");
isa_ok($dbh, q{DBI::db}, q{Expect a DBI::db reference});
is($dbh->{AutoCommit}, 1, "AutoCommit is 1");
is($dbh->{BegunWork}, 0, "BegunWork is 0");

$dbh->begin_work();
is($dbh->{AutoCommit}, 0, "AutoCommit is 0");
is($dbh->{BegunWork}, 1, "BegunWork is 1");
is($dbh->disconnect(), 1, q{Expect disconnect() == 1});



__END__

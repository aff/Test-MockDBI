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
is($dbh->disconnect(), 1, q{Expect disconnect() == 1});


#connect with overidding the attr
my $dbh_att = DBI->connect("universe", "mortal", "root-password",{PrintError => 0, RaiseError => 1});
isa_ok($dbh_att, q{DBI::db}, q{Expect a DBI::db reference});
is($dbh_att->{RaiseError}, 1, "RaiseError is set to 1");
is($dbh_att->{PrintError}, 0, "PrintError is set to 0");
is($dbh_att->disconnect(), 1, q{Expect disconnect() == 1});

__END__

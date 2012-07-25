# $Id: errstr.t 236 2008-12-04 10:28:12Z aff $

use warnings;
use strict;

BEGIN { push @ARGV, "--dbitest=42"; }

use Test::More;

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local version of Test::MockDBI
use Test::MockDBI;

plan tests => 7;

my $mock_dbi = Test::MockDBI::get_instance();
cmp_ok($mock_dbi->get_dbi_test_type(), q[==], 42, q{Expect test type 42});

my $dbh = DBI->connect();
my $sth = $dbh->prepare('select foo from bar');

# ------ errstr should be undef by default
ok(!$sth->errstr, q{expect sth->errstr to be undefined});
is($sth->finish(), 1, "finish()");

# ------ set errstr to true in mode 42
$mock_dbi->set_errstr(42, 'sql failed at line 53');

# ------ errstr should now be set
is($sth->errstr, 'sql failed at line 53', q{expect sth->errstr to be 'sql failed at line 53'});
is($sth->finish(), 1, "finish()");

# ------ set errstr to false in mode 42
$mock_dbi->set_errstr(42);
$dbh = DBI->connect();
$sth = $dbh->prepare('select foo from bar');

# ------ errstr should now be undefined
ok(!$sth->errstr, q{expect sth->errstr to be undefined});
is($sth->finish(), 1, "finish()");

__END__

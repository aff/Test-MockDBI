# Test RaiseError

# $Id: $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=1"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking
use Test::More;        # advanced testing
use Data::Dumper;

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;     # what we are testing


# ------ define variables
my $dbh        = undef;    # mock DBI database handle
my $md         = undef;    # Test::MockDBI instance

$md	= Test::MockDBI::get_instance();
isa_ok($md, q{Test::MockDBI}, q{Expect a Test::MockDBI reference});

# Connect and prepare
$dbh = DBI->connect("DBD::DB","testuser","testpwd");
isa_ok($dbh, q{DBI::db}, q{Expect a DBI::db reference});

$dbh->{RaiseError} = 1;
$dbh->{PrintError} = 0;
$dbh->{AutoCommit} = 0;

# -- methods that are "bad" should fail
subtest "RaiseError bad" => sub{
  
  my @methods = qw( commit rollback );
  
  foreach my $method ( @methods ){
    my $retval = undef;
    $md->bad_method($method, 1, ".*");  # set to fail

    eval{
      $retval = $dbh->$method();
    };
    ok($@, '$@ is set for method ' . $method);
  }
  done_testing();
};

# -- methods that require argument(s) should fail without any
subtest "RaiseError missing arguments" => sub{
  
  my @methods = qw( bind_columns bind_param bind_param_inout );
  
  foreach my $method ( @methods ){
    my $retval = undef;
    eval{
      $retval = $dbh->$method();
    };
    ok($@, '$@ is set for method ' . $method) && diag($@);
  }
  done_testing();
};

done_testing();

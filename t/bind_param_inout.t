# Test making DBI parameters bad

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest"; }

# ------ use/require pragmas
use strict;        # better compile-time checking
use warnings;      # better run-time checking
use Test::More;    # advanced testing
use Data::Dumper;
use Test::Warn;

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;                 # what we are testing

# ------ define variables
my $dbh = undef;                   # mock DBI database handle
my $md  = undef;                   # Test::MockDBI instance

$md = Test::MockDBI::get_instance("debug=true");
isa_ok($md, q{Test::MockDBI}, q{Expect a Test::MockDBI reference});

# Connect and prepare
$dbh = DBI->connect();
isa_ok($dbh, q{DBI::db}, q{Expect a DBI::db reference});

subtest "Success" => sub {
  subtest "Successful bind_param_inout" => sub { bindinout_success(); };
  done_testing();
};

subtest "Failure" => sub {
  subtest "Failing bind_param_inout" => sub { bindinout_failure(); };
  done_testing();
};

sub bindinout_success {

  # success case
  $dbh->prepare("return values are set");
  my $column1     = 0.125;
  my $column2     = "China";
  my $column3 = -1421;
  $md->set_inout_hashref(
    1,
    "inout values are set",
    { 1 => $column1, 2 => $column2, 3 => $column3 }
  );

  # my $rv1;
  # my $rv2;
  # my $rv3;
  my $rv1 = 0;
  my $rv2 = 0;
  my $rv3 = 0;
  $dbh->bind_param_inout(1, \$rv1);
  $dbh->bind_param_inout(2, \$rv2);
  $dbh->bind_param_inout(3, \$rv3);
  $dbh->execute();

  ok(
    $rv1 == $column1 && $rv2 eq $column2 && $rv3 == $column3,
    "return values are set and has returned ($rv1, $rv2, $rv3)"
  );

  $dbh->finish();
}

sub bindinout_failure {

  # failing case
  $dbh->prepare("return value is set with failure SQLState and SQLCode");

  my $warn = qr/DBI::db bind_columns failed/;
  warnings_like { $dbh->bind_columns() } $warn,
"Expect warning like DBI::db bind_columns failed: SQL0100 There are no columns for binding. SQLSTATE=02000";

  $md->set_retval_scalar(1,
    "return value is set with failure SQLState and SQLCode");

  my @ret_val = ();
  $dbh->bind_param_inout(5, \@ret_val, 22);
  $dbh->execute();

  ok(
    $ret_val[0]->[0] eq '02000' && $ret_val[0]->[1] eq '+100',
"return value is set and has returned the SQLState:$ret_val[0]->[0] and SQLCode:$ret_val[0]->[1]"
  );

  $dbh->finish();

}

done_testing();


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

$md = Test::MockDBI::get_instance();
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
  $dbh->prepare("inout values are set");
  my $column1     = 0.125;
  my $column2     = "China";
  my $column3 = -1421;
  $md->set_inout_hashref(
    1,
    "inout values are set",
    { 1 => $column1, 2 => $column2, 3 => $column3 }
  );

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
  $dbh->prepare("return undef if ARRAY ref is used");

  my @ret_val = ();

  warning_is {
    ok(!$dbh->bind_param_inout(5, \@ret_val, 22),
      q{bind_param_inout should return undef when arg is ARRAY ref});
  }
  q{DBI::db bind_param_inout failed: bind_param_inout needs a reference to a scalar value},
    q{Expect warning on ARRAY ref};


}

done_testing();

__END__


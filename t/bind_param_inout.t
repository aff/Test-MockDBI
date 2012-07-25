# Test making DBI parameters bad

# $Id: bad_param-ok-2of3.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking
use Test::More;        # advanced testing
use Data::Dumper;
use Test::Warn;

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;     # what we are testing


# ------ define variables
my $dbh        = undef;    # mock DBI database handle
my $md         = undef;    # Test::MockDBI instance

$md	= Test::MockDBI::get_instance();
isa_ok($md, q{Test::MockDBI}, q{Expect a Test::MockDBI reference});

# Connect and prepare
$dbh = DBI->connect();
isa_ok($dbh, q{DBI::db}, q{Expect a DBI::db reference});

subtest "Success" => sub {
    
  subtest "With success SQLState and SQLCode" => sub { bindinout_success(); };  
  
done_testing();

};

subtest "Failure" => sub {
    
  subtest "With failure SQLState and SQLCode" => sub { bindinout_failure(); };  
  
done_testing();

};

sub bindinout_success {    
   
    
    
    #success case
    $dbh->prepare("return value is set with success SQLState and SQLCode");
    my $column1     = 0.125;
    my $column2     = "China";
    my $column_many = -1421;
    $dbh->bind_columns(\$column1, \$column2, \$column_many);
    $md->set_retval_scalar(1, "return value is set with success SQLState and SQLCode",
     [ 0.125, "China", -1421, 'SQLState', 'SQLCode' ]);
    
    my @ret_val = ();
    $dbh->bind_param_inout(5, \@ret_val, 22);
    $dbh->execute();
    
    ok($ret_val[0]->[0] == 0.125 && $ret_val[0]->[1] eq "China" && $ret_val[0]->[2] == -1421,
     "return value is set and has returned the SQLState:$ret_val[0]->[3] and SQLCode:$ret_val[0]->[4]");

    $dbh->finish();


}

sub bindinout_failure {
    
   
    #success case
    $dbh->prepare("return value is set with failure SQLState and SQLCode");    
  
    my $warn = qr/DBI::db bind_columns failed/;
    warnings_like { $dbh->bind_columns() } $warn, "Expect warning like DBI::db bind_columns failed: SQL0100 There are no columns for binding. SQLSTATE=02000";

    $md->set_retval_scalar(1, "return value is set with failure SQLState and SQLCode");
    
    my @ret_val = ();
    $dbh->bind_param_inout(5, \@ret_val, 22);
    $dbh->execute();
    
    ok($ret_val[0]->[0] eq '02000' && $ret_val[0]->[1] eq '+100',
 "return value is set and has returned the SQLState:$ret_val[0]->[0] and SQLCode:$ret_val[0]->[1]");

    $dbh->finish();
    
}

done_testing();



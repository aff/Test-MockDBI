# Test PrintError

# $Id: $

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
$dbh = DBI->connect("DBD::DB","testuser","testpwd");
isa_ok($dbh, q{DBI::db}, q{Expect a DBI::db reference});

subtest "PrintError" => sub {
    
  subtest "With PrintError as 0" => sub { check_printerror(0); };
  subtest "With PrintError as 1" => sub { check_printerror(1); };  
  
done_testing();

};

sub check_printerror {    
   
    my $arg = shift;
    $dbh->{PrintError} = $arg;
    $dbh->{RaiseError} = 0;
        
    #success case
    $dbh->prepare("return value is set with success SQLState and SQLCode");  
    
    my $error = $dbh->bind_columns()  if $arg == 0;
    
    my $warning_bind = qr/DBI::db bind_columns failed/;
    warnings_like { $dbh->bind_columns(); } $warning_bind, "Expect warning like DBI::db bind_columns failed: SQL0100 There are no columns for binding. SQLSTATE=02000" if $arg == 1;
        
    my $return = select(STDERR);   
    
    $arg == 0 ? ok($return eq 'main::STDOUT', "No error printed") : ok($return eq 'main::STDERR', "The error printed");
       
   
    $dbh->finish();

}


done_testing();
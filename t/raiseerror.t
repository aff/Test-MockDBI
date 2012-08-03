# Test RaiseError

# $Id: $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest"; }

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

subtest "RaiseError" => sub {
    
  subtest "With RaiseError as 0" => sub { check_raiseerror(0); };
  subtest "With RaiseError as 1" => sub { check_raiseerror(1); };  
  
done_testing();

};

sub check_raiseerror {    
   
    my $PrintError = shift;
    $dbh->{PrintError} = 0;
    $dbh->{RaiseError} = $PrintError;
        
    #success case
    $dbh->prepare("SQL Query");  
    my $return = 1;
    my $error;
    eval {
        $error = $dbh->bind_columns();
        $return = 0;
    }
    or do {       
       #print "Expect error like [".$@ ."]\n";
       my $error =  qr/^DBI::db bind_columns failed/;
       ok($return == 0, "No error raised") if $PrintError == 0;
       like ($@, $error, "Expect error 'DBI::db bind_columns failed: There are no columns for binding'") if $PrintError == 1 ;
    };
    
    
    $dbh->finish();

}


done_testing();



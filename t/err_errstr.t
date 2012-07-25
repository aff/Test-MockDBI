# Test making DBI parameters bad

# $Id: bad_param-ok-2of3.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking
use Test::More;        # advanced testing
use Data::Dumper;
use Test::Warn;
use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;     # what we are testing

plan tests => 18;

# ------ define variables
my $dbh        = undef;    # mock DBI database handle
my $md         = undef;    # Test::MockDBI instance
my @retval     = ();       # return array from fetchrow_array()
my $select     = undef;    # DBI SQL SELECT statement handle

$md	= Test::MockDBI::get_instance();
isa_ok($md, q{Test::MockDBI}, q{Expect a Test::MockDBI reference});

#print DBI->errstr();
#print DBI->err();

# Connect and prepare
$dbh = DBI->connect("","","");

isa_ok($dbh, q{DBI::db}, q{Expect a DBI::db reference});


## Test positive
{
    $dbh->do('Select emp_id from employee_table');
    ok(! defined $dbh->err, "Expect No error");
    
    $dbh->prepare('Select query from User');
    ok(! defined $dbh->errstr(), "Expect no error");
    #ok($dbh->err() ne "Could not prepare, Please check the SQL query", "Expect no error");
    
    my $column = undef;
    
    my $warn = qr/DBI::db bind_param_inout failed/;
    warnings_like { $dbh->bind_param_inout(2,\$column,4 ) } $warn, "Expect warning like DBI::db bind_param_inout failed: SQL0100 The return parameter must be array reference. SQLSTATE=02000";

    ok(defined $dbh->err(), "Expect no error");
    #ok($dbh->err() ne 'Second Parameter must be refernce', "Expect no error");
    $md->set_retval_array(2,"Select query from User", 42);
    
    my $rv = $dbh->fetch();
    
    $dbh->finish();
}


## Test Negative
{
    ## Check do method and pass empty SQL
   
    my $warn = qr/DBI::db do failed/;
    warnings_like { $dbh->do("") } $warn, "Expect warning like DBI::db do failed: SQL0100 Expect SQL query. SQLSTATE=02000";

    ok( $dbh->errstr eq 'Expect SQL query', "Expect error");
    
    ## Passing empty SQL, method shud error out
    my $warning = qr/DBI::db prepare failed/;
    warnings_like { $dbh->prepare("") } $warning, "Expect warning like DBI::db prepare failed: SQL0100 Could not prepare. SQLSTATE=02000";

    ok($dbh->errstr eq "Could not prepare, Please check the SQL query", "Expect error");
    
    # Passing scalar value to method, it shud errot out
    my $column = 0;
    
    my $warning_bind = qr/DBI::db bind_param_inout failed/;
    warnings_like { $dbh->bind_param_inout(2,$column,4 ); } $warning_bind, "Expect warning like DBI::db bind_param_inout failed: SQL0100 The return parameter must be array reference. SQLSTATE=02000";

    ok($dbh->err eq 'The return paramater must be array reference', "Expect error");
    
    # When Auto commit is 1, expect commit to set an error message
    
    my $warn_commit = [qr/Cannot commit when AutoCommit/, qr/DBI::db commit failed/];
    warnings_like { $dbh->commit() } $warn_commit, "Expect warning like (Cannot commit when AutoCommit is on) DBI::db commit failed: SQL0100 Cannot commit when AutoCommit is on. SQLSTATE=02000";

    ok( $dbh->errstr eq 'Cannot commit when AutoCommit is on', "Expect error");
    
    # When AutoCommit is 1, expect rollback to set an error msg
    
    my $warn_rollback = [qr/Cannot rollback when AutoCommit/, qr/DBI::db rollback failed/];
    warnings_like { $dbh->rollback(); } $warn_rollback, "Expect warning like (Cannot rollback when AutoCommit is on) DBI::db rollback failed: SQL0100 Cannot rollback when AutoCommit is on. SQLSTATE=02000";

    ok( $dbh->err eq 'Cannot rollback when AutoCommit is on', "Expect error");
    
    $dbh->finish();
}

# test DBI err and errstr
{
    ok(defined DBI->err(), "DB Engine Native Error Code - Could not make fake connection");
    
    ok(defined DBI->errstr(), "Could not make fake connection");
    
}

$dbh->disconnect();

# Test making DBI parameters bad

# $Id: bad_param-diff-type.t 246 2008-12-04 13:01:22Z aff $

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

# ------ define variables
my $dbh        = undef;    # mock DBI database handle
my $md         = undef;    # Test::MockDBI instance
my @retval     = ();       # return array from fetchrow_array()
my $select     = undef;    # DBI SQL SELECT statement handle



# Connect and prepare


my $result = {
                commit => {
                    select => [ { fruit_name => 'Orange' } ],
                    insert => [ { fruit_name => 'Orange' }, { fruit_name => 'apple' } ],
                    update => [ { fruit_name => 'Orange' }, { fruit_name => 'Apple' } ],
                    delete => [ { fruit_name => 'Orange' } ],
                },
                rollback => {
                    select => [ { fruit_name => 'Orange' } ],
                    insert => [ { fruit_name => 'Orange' } ],
                    update => [ { fruit_name => 'Orange' } ],
                    delete => [ { fruit_name => 'Orange' } ],
                }
            };

my $sql = {
           select => "select fruit_name from fruits",
           insert => 'insert into fruits values "apple"',
           delete => "delete fruits where fruit_name='apple'",
           update => "update fruits set fruit_name='Apple' where fruit_name='apple'"
};

subtest "With AutoCommit = 0" => sub {
  subtest "With Commit and no Rollback (AutoCommit = 0)" => sub { commit_test(1,0,0); };
  subtest "With no Commit and with Rollback (AutoCommit = 0)" => sub { commit_test(0,1,0); };
  subtest "With Commit and then Rollback (AutoCommit = 0)" => sub { commit_test(1,1,0); };
  subtest "With Rollback and then Commit (AutoCommit = 0)" => sub { commit_Rollbacktest(1,1,0); };
  
done_testing();

};

subtest "With AutoCommit = 1" => sub {
  subtest "With Commit and no Rollback (AutoCommit = 1)" => sub { commit_test(1,0,1); };
  subtest "With no Commit and with Rollback (AutoCommit = 1)" => sub { commit_test(0,1,1); };
  subtest "With Commit and then Rollback (AutoCommit = 1)" => sub { commit_test(1,1,1); };
  subtest "With Rollback and then Commit (AutoCommit = 1)" => sub { commit_Rollbacktest(1,1,1); };
  
done_testing();

};    
    
sub commit_test {
    
    my $commit_flag = shift;
    my $rollback_flag = shift;
    my $autocommit = shift;
    
     foreach my $sql_type( keys %$sql ){
        
        $md	= Test::MockDBI::get_instance();
        isa_ok($md, q{Test::MockDBI}, q{Expect a Test::MockDBI reference});
        $dbh = DBI->connect("", "", "",{ AutoCommit => $autocommit });
        isa_ok($dbh, q{DBI::db}, q{Expect a DBI::db reference});
        
        
        my $status = $md->set_retval_scalar(2, $sql->{$sql_type}, [ $result->{commit}->{$sql_type} ] ) ;
        $dbh->prepare( $sql->{$sql_type} );
        
        my $warn = [qr/Cannot commit when AutoCommit/, qr/DBI::db commit failed/];
        warnings_like { $dbh->commit() } $warn, "Expect warning like (Testing commit for [ $sql_type ] Expect Success) DBI::db commit failed: SQL0100 Cannot commit when AutoCommit is on. SQLSTATE=02000" if ($commit_flag == 1 && $autocommit == 1);

        ok($dbh->commit(), "Testing commit for [ $sql_type ] Expect Success") if ($commit_flag == 1 && $autocommit == 0);
        
        my $warning = [qr/Cannot rollback when AutoCommit/, qr/DBI::db rollback failed/];
        warnings_like { $dbh->rollback() } $warning, "Expect warning like (Testing rollback for [ $sql_type ] Expect Success) DBI::db rollback failed: SQL0100 Cannot rollback when AutoCommit is on. SQLSTATE=02000" if ($rollback_flag == 1 && $autocommit == 1);

        ok($dbh->rollback(), "Testing rollback for [ $sql_type ] Expect Success") if ($rollback_flag == 1 && $autocommit == 0);
    
        my $retval = $dbh->fetchall_arrayref();    
        
        if ( $commit_flag  == 0 && $autocommit == 0 && $sql_type ne 'select'){
                        ok(! length $retval, q{Expect '' for matching sql});
                        $dbh->finish();
                        next;
        }
        
        ok(defined($retval), q{Expect defined for matching sql});
        
        isa_ok($retval, q{ARRAY}, q{Expect array ref});
    
        is_deeply( $retval, [ $result->{commit}->{$sql_type} ], "Is-deeply Testing [ $sql_type ] Expect Success" );
        $dbh->finish();
        
    }
}

sub commit_Rollbacktest {
    
    my $commit_flag = shift;
    my $rollback_flag = shift;
    my $autocommit = shift;
    
     foreach my $sql_type( keys %$sql ){
        
        $md	= Test::MockDBI::get_instance();
        isa_ok($md, q{Test::MockDBI}, q{Expect a Test::MockDBI reference});
        $dbh = DBI->connect("", "", "",{ AutoCommit => $autocommit });
        isa_ok($dbh, q{DBI::db}, q{Expect a DBI::db reference});
        my $autocommit = $dbh->{AutoCommit};
        
        my $status = $md->set_retval_scalar(2, $sql->{$sql_type}, [ $result->{commit}->{$sql_type} ] ) ;
        $dbh->prepare( $sql->{$sql_type} );
        
        my $warning = [qr/Cannot rollback when AutoCommit/, qr/DBI::db rollback failed/];
        warnings_like { $dbh->rollback() } $warning, "Expect warning like (Testing rollback for [ $sql_type ] Expect Success) DBI::db rollback failed: SQL0100 Cannot rollback when AutoCommit is on. SQLSTATE=02000" if ($rollback_flag == 1 && $autocommit == 1);

        ok($dbh->rollback(), "Testing rollback for [ $sql_type ] Expect Success") if ($rollback_flag == 1 && $autocommit == 0);
        
        my $warn = [qr/Cannot commit when AutoCommit/, qr/DBI::db commit failed/];
        warnings_like { $dbh->commit() } $warn, "Expect warning like (Testing commit for [ $sql_type ] Expect Success) DBI::db commit failed: SQL0100 Cannot commit when AutoCommit is on. SQLSTATE=02000" if ($commit_flag == 1 && $autocommit == 1);

        ok($dbh->commit(), "Testing commit for [ $sql_type ] Expect Success") if ($commit_flag == 1 && $autocommit == 0);
    
        my $retval = $dbh->fetchall_arrayref();    
        
        if ( $commit_flag  == 1 && $autocommit == 0 && $sql_type ne 'select'){
                        ok(! length $retval, q{Expect '' for matching sql});
                        $dbh->finish();
                        next;
        }
        
        ok(defined($retval), q{Expect defined for matching sql});
        
        isa_ok($retval, q{ARRAY}, q{Expect array ref});
    
        is_deeply( $retval, [ $result->{commit}->{$sql_type} ], "Is-deeply Testing [ $sql_type ] Expect Success" );
        $dbh->finish();
        
    }
}

done_testing();

__END__

=pod

=head1 TEST COMMENT

Setting a param to be bad in mode 3 should not affect queries in mode
2.

=cut

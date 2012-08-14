use strict;
use warnings;
use Test::More;

use_ok('Test::MockDBI');

my $mockdbi = Test::MockDBI::get_instance();

my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1');

isa_ok($dbh, 'DBI::db');

{
  #Checking that bind_param_inout works
  my $number = 10;
  
  #The sql to be used
  my $sql = 'CALL PROCEDURE update_number(?)';
  
  #Setting the retval for the inout parameter
  #This should ensure that $number is 15 after execute is called
  $mockdbi->set_inout_value($sql, 1, 15);
  
  my $sth = $dbh->prepare($sql);
  
  $sth->bind_param_inout(1, \$number);
  
  $sth->execute();
  
  cmp_ok($number, '==', 15, '$number should be 15');
}
{
  #Having a mixture of normal params and inout params
  my $inout1 = 10;
  my $inout2 = 20;
  
  my $sql = 'CALL PROCEDURE switchandmultiply(?, ?, ?)';
  
  #Setting the retval for the inout parameter
  #This should ensure that $inout1 is 40 after execute is called
  $mockdbi->set_inout_value($sql, 1, 40);
  #This should ensure that $inout2 is 20 after execute is called
  $mockdbi->set_inout_value($sql, 3, 20);
  
  my $sth = $dbh->prepare($sql);
  
  $sth->bind_param_inout(1, \$inout1);
  $sth->bind_param(2, 2);
  $sth->bind_param_inout(3, \$inout2);
  
  
  $sth->execute();
  cmp_ok($inout1, '==', 40, '$inout1 == 40');
  cmp_ok($inout2, '==', 20, '$inout2 == 20');
  
}
done_testing();
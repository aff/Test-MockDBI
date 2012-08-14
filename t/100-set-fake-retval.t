use strict;
use warnings;
use Test::More;
use Test::Warn;

use_ok('Test::MockDBI');

my $instance = Test::MockDBI::get_instance();

{
  #Setting a fake retval for the prepare method
  $instance->set_retval( method => 'prepare', retval => undef);
  
  
  my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1');
  
  my $sth = $dbh->prepare('SELECT * FROM sometable');
  
  ok(!$sth, '$dbh->prepare returned undef');
}
{
  #Setting a fake retval with custom DBI err & errstr
  my %args = ( method => 'prepare', retval => undef, err => 99, errstr => 'Custom DBI error' );
  $instance->set_retval( %args );
  
  my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1');
  
  my $sth = $dbh->prepare('SELECT * FROM sometable');
  
  ok(!$sth, '$dbh->prepare returned undef');
  cmp_ok($dbh->err, '==', $args{err}, '$sth->err is ' . $args{err});
  cmp_ok($dbh->errstr, 'eq', $args{errstr}, '$sth->errstr is ' . $args{errstr});
}
{
  #Setting a fake retval should fail if no method is provided
  my %args = ( retval => undef, err => 99, errstr => 'Custom DBI error' );
  warning_like{
    ok(!$instance->set_retval( %args ), "set_retval fails without a method");
  } qr/No method provided/, "set_retval displays warning on no method";
}
{
  #Method must be a scalar string
  my %args = ( method => sub{ return 'somemethod';}, retval => undef, err => 99, errstr => 'Custom DBI error' );
  warning_like{
    ok(!$instance->set_retval( %args ), "set_retval fails with an invalid method");
  } qr/Parameter method must be a scalar string/, "set_retval displays warning on invalid method";
}

{
  #If provided sql must be a scalar string
  my %args = ( method => 'prepare', sql => ['sql'], retval => undef, err => 99, errstr => 'Custom DBI error' );
  warning_like{
    ok(!$instance->set_retval( %args ), "set_retval fails with an invalid sql");
  } qr/Parameter SQL must be a scalar string/, "set_retval displays warning on invalid sql";
}

{
  #A retval must be provided
  my %args = ( method => 'prepare', err => 99, errstr => 'Custom DBI error' );
  warning_like{
    ok(!$instance->set_retval( %args ), "set_retval fails without a retval");
  } qr/No retval provided/, "set_retval displays warning when called without a retval";
}
done_testing();
use strict;
use warnings;
use Test::More;

use_ok('Test::MockDBI');

my $instance = Test::MockDBI::get_instance();

{
  #Setting a fake retval for the prepare method
  $instance->set_retval( method => 'prepare', retval => sub {
    return "The returnvalue";
  });
  
  
  my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1');
  
  my $sth = $dbh->prepare('SELECT * FROM sometable');
  
  cmp_ok($sth, 'eq', 'The returnvalue', '$dbh->prepare returned \'The returnvalue\'');
}

done_testing();
use strict;
use warnings;

use Test::More;

use_ok('Test::MockDBI');
my $mockinst = Test::MockDBI::get_instance();

my $dbh = DBI->connect('DBI:mysql:somedb', 'user1', 'password1');

{
  my $sql = 'SELECT id FROM db WHERE id < ?';
  my $sth = $dbh->prepare($sql);
  #Setting 10 as a bad parameter
  ok($mockinst->bad_param(10, $sql), "Successfully set 10 to be a bad_param");
  
  ok(!$sth->bind_param(1, 10), "bind_param fails for value 10");
  ok($sth->bind_param(1, 11), "bind_param succeeds for value 11");
}


done_testing();
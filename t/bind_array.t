# Test::MockDBI bind_array() helper function testing.

# $Id: bind_array.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest"; }


# ------ use/require pragmas
use strict;				                # better compile-time checking
use warnings;				            # better run-time checking
use Test::More tests => 20;		        # advanced testing
use File::Spec::Functions;
use lib catdir qw ( blib lib );			            # use local module
use Test::MockDBI;			            # what we are testing


# ------ define variables
my $column1         = "";               # first column to bind
my $column2         = "";               # second column to bind
my $column_many     = "";               # first of many columns to bind
my $dbh             = "";				# mock DBI database handle
my $new_column1     = "";               # new first column to bind
my $new_column2     = "";               # new second column to bind
my $new_column_many = "";               # new first of many columns to bind
my $ok              = 0;                # saved OK value from previous fetch*
my $tmd					                # Test::MockDBI instance
 = Test::MockDBI::get_instance();


# ------ fake DBI object for testing
$dbh = DBI->connect();


# ------ array - no rows returned
$dbh->prepare("no rows returned");
$column1 = 1014;
$dbh->bind_columns(\$column1);
$dbh->fetch();
is($column1, 1014,
 "array - no rows returned");


# ------ 1 column for an array
$dbh->prepare("TEST 1 column for an array");
$column1 = 0;
$dbh->bind_columns(\$column1);
my $get_1_column_array_count = 0;
sub get_1_column_array {
    if ($get_1_column_array_count++ < 1) {
        return ( 42 );
    }
    return ();
}
$tmd->set_retval_array(1, "TEST 1 column for an array", \&get_1_column_array);
$dbh->fetch();
is($column1, 42,
 "1 column for an array");


# ------ array-bound variables undisturbed after fetch ends
$dbh->fetch();
is($column1, 42,
 "array-bound variables undisturbed after fetch ends");


# ------ 2 columns for an array
$dbh->prepare("TEST 2 columns for an array");
$column1 = 0;
$column2 = 0;
$dbh->bind_columns(\$column1, \$column2);
my $get_2_column_array_count = 0;
sub get_2_column_array {
    if ($get_2_column_array_count++ < 1) {
        return ( 42, "universe" );
    }
    return ();
}
$tmd->set_retval_array(1, "TEST 2 columns for an array", \&get_2_column_array);
$dbh->fetch();
ok($column1 == 42 && $column2 eq "universe",
 "2 columns for an array");


# ------ many columns for an array
$dbh->prepare("TEST many columns for an array");
$column1     = 0;
$column2     = 0;
$column_many = 0;
$dbh->bind_columns(\$column1, \$column2, \$column_many);
my $get_many_column_array_count = 0;
sub get_many_column_array {
    if ($get_many_column_array_count++ < 1) {
        return ( 42, "universe", 0.5 );
    }
    return ();
}
$tmd->set_retval_array(1, "TEST many columns for an array", \&get_many_column_array);
$dbh->fetch();
ok($column1 == 42 && $column2 eq "universe" && $column_many == 0.5,
 "many columns for an array");


# ------ many rows returned for an array
# ------ also test that re-binding works OK
$dbh->prepare("TEST many rows returned for an array and rebind");
$new_column1     = 0;
$new_column2     = 0;
$new_column_many = 0;
$dbh->bind_columns(\$new_column1, \$new_column2, \$new_column_many);
my $get_many_row_array_count = -1;
sub get_many_row_array {
    $get_many_row_array_count++;
    if (     $get_many_row_array_count == 0) {
        return ( "Norman Conquest", 7.5, 1066);
    } elsif ($get_many_row_array_count == 1) {
        return ( "Declaration", 22.25, 1776);
    }
    return ();
}
$tmd->set_retval_array(1, "TEST many rows returned for an array and rebind", \&get_many_row_array);
$dbh->fetch();
$ok = ($new_column1 eq "Norman Conquest"
    && $new_column2 == 7.5
    && $new_column_many == 1066);
$dbh->fetch();
ok($ok
    && $new_column1 eq "Declaration"
    && $new_column2 == 22.25
    && $new_column_many == 1776,
 "many rows returned for an array and rebind");


# ------ return value is set by array not coderef, 1 column
$dbh->prepare("return value is set by array not coderef, 1 column");
$column1 = 0;
$dbh->bind_columns(\$column1);
$tmd->set_retval_array(1, "return value is set by array not coderef, 1 column", 312);
$dbh->fetch();
is($column1, 312,
 "return value is set by array not coderef, 1 column");


# ------ return value is set by array not coderef, 2 columns
$dbh->prepare("return value is set by array not coderef, 2 columns");
$column1 = 0;
$column2 = 0;
$dbh->bind_columns(\$column1, \$column2);
$tmd->set_retval_array(1, "return value is set by array not coderef, 2 columns", "Rome", 476);
$dbh->fetch();
ok($column1 eq "Rome" && $column2 == 476,
 "return value is set by array not coderef, 2 columns");


# ------ return value is set by array not coderef, many columns
$dbh->prepare("return value is set by array not coderef, many columns");
$column1     = 0;
$column2     = 0;
$column_many = 0;
$dbh->bind_columns(\$column1, \$column2, \$column_many);
$tmd->set_retval_array(1, "return value is set by array not coderef, many columns",
 0.125, "China", -1421);
$dbh->fetch();
ok($column1 == 0.125 && $column2 eq "China" && $column_many == -1421,
 "return value is set by array not coderef, many columns");


# ------ arrayref - no rows returned
$dbh->prepare("arrayref - no rows returned");
$column1 = 1066;
$dbh->bind_columns(\$column1);
$dbh->fetchrow_arrayref();
is($column1, 1066,
 "arrayref - no rows returned");


# ------ 1 column for an arrayref
$dbh->prepare("TEST 1 column for an arrayref");
$column1 = 0;
$dbh->bind_columns(\$column1);
my $get_1_column_arrayref_count = 0;
sub get_1_column_arrayref {
    if ($get_1_column_arrayref_count++ < 1) {
        return [ 42 ];
    }
    return undef;
}
$tmd->set_retval_scalar(1, "TEST 1 column for an arrayref", \&get_1_column_arrayref);
$dbh->fetchrow_arrayref();
is($column1, 42,
 "1 column for an arrayref");


# ------ arrayref-bound variables undisturbed after fetch ends
$dbh->fetchrow_arrayref();
is($column1, 42,
 "arrayref-bound variables undisturbed after fetch ends");


# ------ 2 columns for an arrayref
$dbh->prepare("TEST 2 columns for an arrayref");
$column1 = 0;
$column2 = 0;
$dbh->bind_columns(\$column1, \$column2);
my $get_2_column_arrayref_count = 0;
sub get_2_column_arrayref {
    if ($get_2_column_arrayref_count++ < 1) {
        return [ 42, "universe" ];
    }
    return undef;
}
$tmd->set_retval_scalar(1, "TEST 2 columns for an arrayref", \&get_2_column_arrayref);
$dbh->fetchrow_arrayref();
ok($column1 == 42 && $column2 eq "universe",
 "2 columns for an arrayref");


# ------ many columns for an arrayref
$dbh->prepare("TEST many columns for an arrayref");
$column1     = 0;
$column2     = 0;
$column_many = 0;
$dbh->bind_columns(\$column1, \$column2, \$column_many);
my $get_many_column_arrayref_count = 0;
sub get_many_column_arrayref {
    if ($get_many_column_arrayref_count++ < 1) {
        return [ 42, "universe", 0.5 ];
    }
    return undef;
}
$tmd->set_retval_scalar(1, "TEST many columns for an arrayref", \&get_many_column_arrayref);
$dbh->fetchrow_arrayref();
ok($column1 == 42 && $column2 eq "universe" && $column_many == 0.5,
 "many columns for an arrayref");


# ------ many rows returned for an arrayref
# ------ also test that re-binding works OK
$dbh->prepare("TEST many rows returned for an arrayref and rebind");
$new_column1     = 0;
$new_column2     = 0;
$new_column_many = 0;
$dbh->bind_columns(\$new_column1, \$new_column2, \$new_column_many);
my $get_many_row_arrayref_count = -1;
sub get_many_row_arrayref {
    $get_many_row_arrayref_count++;
    if (     $get_many_row_arrayref_count == 0) {
        return [ "Norman Conquest", 7.5, 1066];
    } elsif ($get_many_row_arrayref_count == 1) {
        return [ "Declaration", 22.25, 1776];
    }
    return undef;
}
$tmd->set_retval_scalar(1, "TEST many rows returned for an arrayref and rebind",
 \&get_many_row_arrayref);
$dbh->fetchrow_arrayref();
$ok = ($new_column1 eq "Norman Conquest"
    && $new_column2 == 7.5
    && $new_column_many == 1066);
$dbh->fetchrow_arrayref();
ok($ok
    && $new_column1 eq "Declaration"
    && $new_column2 == 22.25
    && $new_column_many == 1776,
 "many rows returned for an arrayref and rebind");


# ------ return value is set by arrayref not coderef, 1 column
$dbh->prepare("return value is set by arrayref not coderef, 1 column");
$column1 = 0;
$dbh->bind_columns(\$column1);
$tmd->set_retval_scalar(1, "return value is set by arrayref not coderef, 1 column", [ 312 ]);
$dbh->fetchrow_arrayref();
is($column1, 312,
 "return value is set by arrayref not coderef, 1 column");


# ------ return value is set by arrayref not coderef, 2 columns
$dbh->prepare("return value is set by arrayref not coderef, 2 columns");
$column1 = 0;
$column2 = 0;
$dbh->bind_columns(\$column1, \$column2);
$tmd->set_retval_scalar(1, "return value is set by arrayref not coderef, 2 columns",
 [ "Rome", 476 ]);
$dbh->fetchrow_arrayref();
ok($column1 eq "Rome" && $column2 == 476,
 "return value is set by arrayref not coderef, 2 columns");


# ------ return value is set by arrayref not coderef, many columns
$dbh->prepare("return value is set by arrayref not coderef, many columns");
$column1     = 0;
$column2     = 0;
$column_many = 0;
$dbh->bind_columns(\$column1, \$column2, \$column_many);
$tmd->set_retval_scalar(1, "return value is set by arrayref not coderef, many columns",
 [ 0.125, "China", -1421 ]);
$dbh->fetchrow_arrayref();
ok($column1 == 0.125 && $column2 eq "China" && $column_many == -1421,
 "return value is set by arrayref not coderef, many columns");

# ------ return value is set by arrayref not coderef, many columns
$dbh->prepare("return value is set by hashref not coderef, many columns");
$column1     = 0;
$column2     = 0;
$column_many = 0;
$dbh->bind_columns(\$column1, \$column2, \$column_many);
$tmd->set_retval_scalar(1, "return value is set by hashref not coderef, many columns",
 [ {test => 1}, "China", -1421 ]);
$dbh->fetchrow_arrayref();
ok(ref $column1 eq 'HASH',
 "return value of coulmn 1 is hashref");
ok($column2 eq "China" && $column_many == -1421,
 "return value is set by arrayref not coderef, many columns");

__END__

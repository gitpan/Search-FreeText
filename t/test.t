use strict;
use Test;
use POSIX qw(tmpnam);

BEGIN { plan tests => 7 };

use blib;
use Search::FreeText;
my @results;

my $test = new Search::FreeText(-db => ['DB_File', tmpnam()]);
ok($test);

$test->open_index();
$test->clear_index();
$test->index_document(1, "Hello world");
$test->index_document(2, "World in motion");
$test->index_document(3, "Cruel crazy beautiful world");
$test->index_document(4, "Hey crazy");
$test->close_index();

$test->open_index();
@results = $test->search("Crazy", 10);
$test->close_index();

ok(scalar(@results), 2);
ok($results[0]->[0], 4);
ok($results[1]->[0], 3);

# Stemming should work as well. 

$test->open_index();
@results = $test->search("crazied", 10);
$test->close_index();

ok(scalar(@results), 2);
ok($results[0]->[0], 4);
ok($results[1]->[0], 3);

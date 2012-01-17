#!perl -T

use strict;
use warnings;

use Data::Dumper;
use Test::Deep;
use Test::More;

use Email::ExactTarget;


eval 'use ExactTargetConfig';
$@
	? plan( skip_all => 'Local connection information for ExactTarget required to run tests.' )
	: plan( tests => 1 );

my $config = ExactTargetConfig->new();

TODO:
{
	todo_skip(
		'Delete function not implemented yet, please delete manually ' .
		'john.public@example.com, john.q.public@example.com, and ' .
		'john.doe@example.com in ExactTarget\'s interface.',
		1,
	);
}
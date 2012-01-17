#!perl -T

use strict;
use warnings;

use Test::More;

use Email::ExactTarget;
use Email::ExactTarget::Subscriber;


eval 'use ExactTargetConfig';
$@
	? plan( skip_all => 'Local connection information for ExactTarget required to run tests.' )
	: plan( tests => 5 );

my $config = ExactTargetConfig->new();

like(
	$config->{'username'},
	qr/\w/,
	'The username is defined.',
);

like(
	$config->{'password'},
	qr/\w/,
	'The password is defined.',
);

like(
	$config->{'all_subscribers_list_id'},
	qr/^\d+$/,
	'The all subscribers list ID is an integer.',
);

isa_ok(
	$config->{'test_lists'},
	'ARRAY',
	"\$config->{'test_lists'}",
);

ok(
	scalar( @{ $config->{'test_lists'} || [] } ) >= 2,
	'At least 2 test lists are defined in the "test_lists" key of the config',
);

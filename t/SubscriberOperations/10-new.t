#!perl -T

use strict;
use warnings;

use Test::More;

use Email::ExactTarget;


eval 'use ExactTargetConfig';
$@
	? plan( skip_all => 'Local connection information for ExactTarget required to run tests.' )
	: plan( tests => 3 );

my $config = ExactTargetConfig->new();

# Create an object to communicate with Exact Target
my $exact_target = Email::ExactTarget->new( %$config );
ok(
	defined( $exact_target ),
	'Create a new Email::ExactTarget object.',
) || diag( explain( $exact_target ) );

isa_ok(
	$exact_target,
	'Email::ExactTarget',
	'The object returned by Email::ExactTarget->new()',
) || diag( explain( $exact_target ) );

# Get a subscriber operations object.
my $subscriber_operations = $exact_target->subscriber_operations();
isa_ok(
	$subscriber_operations,
	'Email::ExactTarget::SubscriberOperations',
	'The object returned by subscriber_operations()',
);


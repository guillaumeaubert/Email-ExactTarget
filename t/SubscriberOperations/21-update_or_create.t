#!perl -T

use strict;
use warnings;

use Test::More;
use Data::Dumper;

use Email::ExactTarget;
use Email::ExactTarget::Subscriber;


eval 'use ExactTargetConfig';
$@
	? plan( skip_all => 'Local connection information for ExactTarget required to run tests.' )
	: plan( tests => 9 );

my $config = ExactTargetConfig->new();

# Create an object to communicate with Exact Target.
my $exact_target = Email::ExactTarget->new( %$config );
ok(
	defined( $exact_target ),
	'Create a new Email::ExactTarget object.',
) || diag( explain( $exact_target ) );

# Get a subscriber operations object.
ok(
	my $subscriber_operations = $exact_target->subscriber_operations(),
	"Subscriber operations object retrieved.",
);

# Create new Subscriber objects.
my $subscribers = [];

# (this one should already exist, per our previous tests)
ok(
	my $subscriber1 = Email::ExactTarget::Subscriber->new(),
	'Created Email::ExactTarget::Subscriber object.',
);
eval
{
	$subscriber1->set(
		{
			'First Name'    => 'John Q.',
			'Last Name'     => 'Public',
			'Email Address' => 'john.q.public@example.com',
		},
		'is_live' => 0,
	);
	$subscriber1->set_lists_status(
		{
			$config->{'test_lists'}->[0] => 'Active',
		},
		'is_live' => 0,
	);
};
ok(
	!$@,
	'Staged changes on the first subscriber.',
) || diag( "Error: $@" );
push( @$subscribers, $subscriber1 );

# (this one will be new)
ok(
	my $subscriber2 = Email::ExactTarget::Subscriber->new(),
	'Created Email::ExactTarget::Subscriber object.',
);
eval
{
	$subscriber2->set(
		{
			'First Name'    => 'John',
			'Last Name'     => 'Doe',
			'Email Address' => 'john.doe@example.com',
		},
		'is_live' => 0,
	);
	$subscriber2->set_lists_status(
		{
			$config->{'test_lists'}->[1] => 'Active',
		},
		'is_live' => 0,
	);
};
ok(
	!$@,
	'Staged changes on the second subscriber.',
) || diag( "Error: $@" );
push( @$subscribers, $subscriber2 );

# First set of updates to set up the testing environment.
eval
{
	$subscriber_operations->update_or_create( $subscribers );
};
ok(
	!$@,
	"No error found when updating/creating the objects.",
) || diag( "Error: $@" );

# Check that there is no error on the subscriber objects.
foreach my $subscriber ( @$subscribers )
{
	ok(
		!defined( $subscriber->errors() ),
		"No error found on the subscriber object.",
	) || diag( "Errors on the subscriber object:\n" . Dumper( $subscriber->errors() ) );
}

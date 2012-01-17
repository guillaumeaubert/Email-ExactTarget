#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

use Email::ExactTarget;


# Create an object to communicate with Exact Target.
my $exact_target = Email::ExactTarget->new(
	'username'                => 'XXXXX',
	'password'                => 'XXXXX',
	'all_subscribers_list_id' => '12345',
	'verbose'                 => 0,
	'unaccent'                => 1,
);

ok(
	defined( $exact_target ) && $exact_target->isa( 'Email::ExactTarget' ),
	'Create a new Email::ExactTarget object.',
) || diag( explain( $exact_target ) );

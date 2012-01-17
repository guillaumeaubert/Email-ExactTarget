#!perl -T

use strict;
use warnings;

use Test::More tests => 3;

use_ok( 'Email::ExactTarget' );
use_ok( 'Email::ExactTarget::Subscriber' );
use_ok( 'Email::ExactTarget::SubscriberOperations' );

diag( "Testing Email::ExactTarget::SubscriberOperations $Email::ExactTarget::SubscriberOperations::VERSION, Perl $], $^X" );

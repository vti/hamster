package Hamster::Command::Help;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($cb) = @_;

    my $reply = $self->msg->make_reply;

    my $help =<<EOF;
HELP -- this help

NICK        -- show current nick
NICK myname -- set new nick

My new topic           -- create a new topic
*foo *bar My New topic -- create a new topic with foo and bar tags

#                        -- list last 10 topics

#1                       -- show topic #1
#1+                      -- show topic #1 with replies
#1 My new reply          -- post a new reply to the topic #1
#1/2 That's a nice reply -- post a new reply to the reply #1/2

STAT -- show some statistics

LANG    -- show current service message language
LANG en -- set new service message language

PING -- ping bot

EOF

    $reply->add_body($help);

    $reply->send;

    return $cb->();
}

1;

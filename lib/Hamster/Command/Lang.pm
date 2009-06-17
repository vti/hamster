package Hamster::Command::Lang;

use base 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($human, $msg, $cb) = @_;

    my $reply = $msg->make_reply;

    $reply->add_body($self->hamster->localizator->language);

    $reply->send;

    return $cb->();
}

1;

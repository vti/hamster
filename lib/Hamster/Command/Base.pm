package Hamster::Command::Base;

use Mouse;

has hamster => (
    is  => 'rw',
    isa => 'Hamster'
);

has args => (
    isa     => 'ArrayRef',
    is      => 'rw',
    default => sub { [] }
);

has human => (
    isa => 'Hamster::Human',
    is  => 'rw'
);

has msg => (
    is  => 'rw'
);

sub render {
    my $self = shift;
    my $template = shift;

    return $self->hamster->view->$template($self->human->lang, @_);
}

sub send {
    my $self = shift;
    my ($body, $cb) = @_;

    my $reply = $self->msg->make_reply;

    $reply->add_body($body);

    $reply->send;

    $cb->();
}

1;

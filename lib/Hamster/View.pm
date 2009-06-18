package Hamster::View;

use Mouse;

has hamster => (
    isa => 'Hamster',
    is  => 'rw'
);

sub topic {
    my $self = shift;
    my ($lang, $topic) = @_;

    my @out = ();

    push @out, $self->hamster->loc($lang, '#[_1] by [_2] (Replies: [_3])',
        $topic->id, $topic->author, $topic->replies);

    push @out, $topic->body;

    return join("\n", @out);
}

sub reply {
    my $self = shift;
    my ($lang, $reply) = @_;

    my @out = ();

    push @out, $self->hamster->loc($lang, '#[_1]/[_2] by [_3]',
        $reply->topic_id, $reply->seq, $reply->author);

    if ($reply->parent_body) {
        push @out, '>@' . $reply->parent_author . ', ' . $reply->parent_body;
    }

    push @out, $reply->body;

    return join("\n", @out);
}

sub stat {
    my $self = shift;
    my ($lang, $total, $active, $online) = @_;

    my @out = ();

    push @out, $self->hamster->loc($lang, 'Total : [_1]', $total);
    push @out, $self->hamster->loc($lang, 'Active: [_1]', $active);
    push @out, $self->hamster->loc($lang, 'Online: [_1]', $online);

    return join("\n", @out);
}

1;

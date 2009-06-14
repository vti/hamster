package Hamster::Command::Post;

use Mouse;
use AnyEvent::XMPP::IM::Message;

has title_length => (
    isa     => 'Int',
    is      => 'rw',
    default => 80
);

has save => (
    is  => 'rw'
);

sub run {
    my $self = shift;
    my ($hamster, $human, $message) = @_;

    my ($title, $content, $tags) = $self->_parse($message);

    if ($self->save) {
        return $self->save->($hamster, $human, $title, $content, $tags);
    }

    return AnyEvent::XMPP::IM::Message->new(
        to   => $human->jid,
        body => 'Created'
    );
}

sub _parse {
    my $self = shift;
    my $message = shift;
    return unless $message;

    my $tags = $self->_parse_tags(\$message);

    my $title = $self->_parse_title(\$message);

    return ($title, $message, $tags);
}

sub _parse_tags {
    my $self = shift;
    my $message = shift;

    my @tags = ();

    while ($$message =~ s/^\*([^\s]+)\s*//) {
        push @tags, $1;
    }

    return \@tags;
}

sub _parse_title {
    my $self = shift;
    my $message = shift;

    my $title = $$message;

    if ($$message =~ s/(.*?)(?:\.|\!|\?)\s+//) {
        $title = $1;
    }

    if (length $title > $self->title_length) {
        $title = substr($title, 0, $self->title_length);

        $title =~ s/\s+[^\s]+$//;

        $title .= '...';
    }

    return $title;
}

1;

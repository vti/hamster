package Hamster::Command::Create;

use base 'Hamster::Command::Base';

use Hamster::Answer;

sub run {
    my $self = shift;
    my ($message, $cb) = @_;

    my $body = $message->any_body;

    my ($text, $tags) = $self->_parse($body);

    my $answer = Hamster::Answer->new(body => "Topic '$text' was created");

    return $cb->($answer);
}

sub _parse {
    my $self    = shift;
    my $message = shift;
    return unless $message;

    my $tags = $self->_parse_tags(\$message);

    return ($message, $tags);
}

sub _parse_tags {
    my $self    = shift;
    my $message = shift;

    my @tags = ();

    while ($$message =~ s/^\*([^\s]+)\s*//) {
        push @tags, $1;
    }

    return \@tags;
}

1;

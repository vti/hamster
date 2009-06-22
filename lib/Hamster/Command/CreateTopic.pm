package Hamster::Command::CreateTopic;

use Mouse;

extends 'Hamster::Command::Base';

use Hamster::Topic;
use Hamster::Subscription;

sub run {
    my $self = shift;
    my ($cb) = @_;

    my ($body) = @{$self->args};

    my ($text, $tags) = $self->_parse($body);

    my $dbh = $self->hamster->dbh;

    Hamster::Topic->create(
        $dbh,
        {   human_id => $self->human->id,
            body     => $text,
            tags     => $tags,
            jid      => $self->human->jid,
            resource => $self->human->resource
        },
        sub {
            my ($dbh, $topic) = @_;

            Hamster::Subscription->create(
                $dbh,
                {   master_type => 't',
                    master_id   => $topic->id,
                    human_id    => $self->human->id
                },
                sub {
                    $self->send('Topic was created', sub { $cb->() });
                }
            );
        }
    );
}

sub _parse {
    my $self = shift;
    my $msg  = shift;
    return unless $msg;

    my $tags = $self->_parse_tags(\$msg);

    return ($msg, $tags);
}

sub _parse_tags {
    my $self = shift;
    my $msg  = shift;

    my @tags = ();

    while ($$msg =~ s/^\*([^\s]+)\s*//) {
        push @tags, $1;
    }

    return \@tags;
}

1;

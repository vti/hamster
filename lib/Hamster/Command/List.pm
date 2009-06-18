package Hamster::Command::List;

use Mouse;

extends 'Hamster::Command::Base';

use Hamster::Topic;

sub run {
    my $self = shift;
    my ($cb) = @_;

    my $dbh = $self->hamster->dbh;

    Hamster::Topic->find_all(
        $dbh,
        {},
        sub {
            my ($dbh, $topics) = @_;

            if (@$topics) {
                my $body = '';

                foreach my $topic (@$topics) {
                    $body
                      .= $self->hamster->localizator->loc($self->human->lang,
                        '#[_1] by [_2] (Replies: [_3])',
                        $topic->id, $topic->author, $topic->replies)
                      . "\n";
                    $body .= $topic->body . "\n";
                }

                return $self->send($body, sub { $cb->() });
            }
            else {
                return $self->send('No topics yet', sub { $cb->() });
            }
        }
    );
}

1;

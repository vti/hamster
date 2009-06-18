package Hamster::Command::Subscribe;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($cb) = @_;

    my ($type, $id) = @{$self->args};

    if (!$type) {
        my $reply = $self->msg->make_reply;

        $reply->add_body("Your subscriptions:");

        $reply->send;

        return $cb->();
    }
    elsif ($type eq '#') {
        my $dbh = $self->hamster->dbh;

        $dbh->exec(
            qq/SELECT id FROM `topic` WHERE `id`=?/ => ($id) => sub {
                my ($dbh, $rows, $rv) = @_;

                if (@$rows) {
                    $dbh->exec(
                        qq/INSERT INTO `subscription` (master_type, master_id, human_id)
                            VALUES (?, ?, ?)/ => ('t', $id, $self->human->id) =>
                          sub {
                            my ($dbh, $rows, $rv) = @_;

                            my $reply = $self->msg->make_reply;

                            $reply->add_body("You were subscribed");

                            $reply->send;

                            return $cb->();
                        }
                    );
                }
                else {
                    my $reply = $self->msg->make_reply;

                    $reply->add_body("Topic not found");

                    $reply->send;

                    return $cb->();
                }
            }
        );
    }

    return $cb->();
}

1;

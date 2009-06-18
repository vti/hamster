package Hamster::Command::Unsubscribe;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($cb) = @_;

    my ($type, $id) = @{$self->args};

    if ($type eq '#') {
        my $dbh = $self->hamster->dbh;

        return $dbh->exec(
            qq/SELECT id FROM `topic` WHERE `id`=?/ => ($id) => sub {
                my ($dbh, $rows, $rv) = @_;

                if (@$rows) {
                    $self->_delete_subscription($dbh, 't', $id,
                        sub { $cb->() });
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

sub _delete_subscription {
    my ($self, $dbh, $type, $id, $cb) = @_;

    $dbh->exec(
        qq/DELETE FROM `subscription` WHERE master_type=? AND master_id=? AND human_id=?/
          => ($type, $id, $self->human->id) => sub {
            my ($dbh, $rows, $rv) = @_;

            my $reply = $self->msg->make_reply;

            $reply->add_body("You were unsubscribed");

            $reply->send;

            $cb->();
        }
    );
}

1;

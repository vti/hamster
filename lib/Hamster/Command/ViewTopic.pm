package Hamster::Command::ViewTopic;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($human, $msg, $cb) = @_;

    my $dbh = $self->hamster->dbh;

    my ($id) = ($msg->any_body =~ m/^#(\d+)$/);

    $dbh->exec(
        qq/SELECT body FROM `topic` WHERE `id`=?/ =>
          ($id) => sub {
            my ($dbh, $rows, $rv) = @_;

            my $reply = $msg->make_reply;

            if (@$rows) {
                $reply->add_body($rows->[0]->[0]);
            }
            else {
                $reply->add_body("Topic was not found");
            }

            $reply->send;

            return $cb->();
        }
    );
}

1;

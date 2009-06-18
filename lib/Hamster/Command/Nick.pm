package Hamster::Command::Nick;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($cb) = @_;

    my ($nick) = @{$self->args};
    my $old_nick = $self->human->nick;

    if (!$nick) {
        my $reply = $self->msg->make_reply;

        if ($old_nick) {
            $reply->add_body("Your current nick: $old_nick");
        }
        else {
            $reply->add_body("You didn't choose any nickname yet");
        }

        $reply->send;

        return $cb->();
    }
    else {
        my $dbh = $self->hamster->dbh;

        if ($old_nick && $old_nick eq $nick) {
            my $reply = $self->msg->make_reply;

            $reply->add_body('It is the same nickname');

            $reply->send;

            $cb->();
        }
        else {
            $dbh->exec(
                qq/SELECT nick FROM `human` WHERE `nick`=?/ => ($nick) => sub {
                    my ($dbh, $rows, $rv) = @_;

                    # If we found topic
                    if (@$rows) {
                        my $reply = $self->msg->make_reply;

                        $reply->add_body('This nickname is already taken');

                        $reply->send;

                        $cb->();
                    }
                    else {
                        $dbh->exec(
                            qq/UPDATE human SET nick=? WHERE id=?/ =>
                              ($nick, $self->human->id) => sub {
                                my ($dbh, $rows, $rv) = @_;

                                my $reply = $self->msg->make_reply;

                                $reply->add_body('Your nickname was changed');

                                $reply->send;

                                $cb->();
                            }
                        );
                    }
                }
            );
        }
    }
}

1;

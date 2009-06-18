package Hamster::Command::Nick;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($cb) = @_;

    my ($nick) = @{$self->args};
    my $old_nick = $self->human->nick;

    if (!$nick) {
        if ($old_nick) {
            return $self->send("Your current nick: $old_nick",
                sub { $cb->() });
        }
        else {
            return $self->send("You didn't choose any nickname yet",
                sub { $cb->() });
        }
    }
    else {
        my $dbh = $self->hamster->dbh;

        if ($old_nick && $old_nick eq $nick) {
            my $reply = $self->msg->make_reply;

            return $self->send("It is the same nickname", sub { $cb->() });
        }
        else {
            $self->human->update_nick(
                $dbh,
                {nick => $nick},
                sub {
                    my ($dbh, $ok) = @_;

                    if ($ok) {
                        return $self->send("Your nickname was changed",
                            sub { $cb->() });
                    }
                    else {
                        return $self->send("This nickname is already taken",
                            sub { $cb->() });
                    }
                }
            );
        }
    }
}

1;

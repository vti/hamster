package Hamster::Command::Lang;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($cb) = @_;

    my $dbh = $self->hamster->dbh;

    my ($lang) = @{$self->args};

    if ($lang) {
        if (grep { $_ eq $lang } @{$self->hamster->localizator->languages}) {
            $dbh->exec(
                qq/UPDATE human SET lang=? WHERE `id`=?/ =>
                  ($lang, $self->human->id) => sub {
                    my ($dbh, $rows, $rv) = @_;

                    my $reply = $self->msg->make_reply;

                    $reply->add_body('Your current language is ' . $lang);

                    $reply->send;

                    return $cb->();
                }
            );
        }
        else {
            my $reply = $self->msg->make_reply;

            $reply->add_body('Unknown language');

            $reply->send;

            return $cb->();
        }
    }
    else {
        my $reply = $self->msg->make_reply;

        $reply->add_body($self->human->lang);

        $reply->send;

        return $cb->();
    }
}

1;

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
            return $self->human->update_lang(
                $dbh,
                {lang => $lang},
                sub {
                    return $self->send('Your current language is ' . $lang,
                        sub { $cb->(); });
                }
            );
        }
        else {
            return $self->send('Unknown language', sub { $cb->() });
        }
    }
    else {
        return $self->send($self->human->lang, sub { $cb->() });
    }
}

1;

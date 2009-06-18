package Hamster::Localizator;

use Mouse;
use Hamster::I18N;

has language => (is => 'rw');

has languages => (is => 'rw', isa => 'ArrayRef', default => sub { [] });

has _handle => (is => 'rw');

has i18n => (
    is      => 'rw',
    default => sub { Hamster::I18N->new }
);

sub BUILD {
    my $self = shift;

    $self->language('en');

    $self->_handle($self->i18n->get_handle($self->language));

    my $path = $INC{join('/', split(/::/, 'Hamster::I18N')) . '.pm'};
    $path =~ s/\.pm$//;

    opendir DIR, $path or die "$path: $!";

    my @languages =
      map { s/\.pm$//; $_ } grep {m/^[a-z]{2}\.pm$/} readdir(DIR);

    closedir DIR;

    $self->languages([@languages]);
}

sub loc {
    my $self = shift;
    my $lang = shift;

    my $handle = $self->_handle;

    if ($self->language ne $lang) {
        $handle = $self->_handle($self->i18n->get_handle($lang));
    }

    return $handle->maketext(@_) if $handle;

    return @_;
}

1;

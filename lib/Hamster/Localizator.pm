package Hamster::Localizator;

use Mouse;
use Hamster::I18N;

has _language => (is => 'rw');

has language_tag => (is => 'rw');

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

    $self->languages();
}

sub language {
    my $self = shift;

    if (@_) {
        my $handle = $self->_handle($self->i18n->get_handle(@_));

        my $lang = ref $handle;
        $lang =~ s/^.*::// if $lang;

        $self->_language($lang);
        $self->language_tag($handle->language_tag);

        return $self;
    }

    return $self->_language;
}

sub loc {
    my $self = shift;

    my $handle = $self->_handle;

    return $handle->maketext(@_) if $handle;

    return @_;
}

1;

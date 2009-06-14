use Test::More tests => 12;

use Hamster::Human;
use Hamster::Command::Post;
use AnyEvent::XMPP::IM::Message;

my $cmd = Hamster::Command::Post->new;
ok($cmd);

my $human = Hamster::Human->new(jid => 'foo@bar.com');

my $msg = $cmd->run(undef, $human, undef);
is($msg->to, 'foo@bar.com');

$cmd->save(
    sub {
        my ($hamster, $human, $title, $content, $tags) = @_;

        is($title,   'hello');
        is($content, 'hello');
        is_deeply($tags, [qw/foo bar/]);

        return AnyEvent::XMPP::IM::Message->new(
            to   => $human->jid,
            body => 'Hello from save'
        );
    }
);
$msg = $cmd->run(undef, $human, '*foo *bar hello');
is($msg->to,   'foo@bar.com');
is($msg->body, 'Hello from save');

$cmd->title_length(3);
$cmd->save(
    sub {
        my ($hamster, $human, $title, $content, $tags) = @_;

        is($title,   'hel...');
        is($content, 'hello');
        is_deeply($tags, [qw/foo bar/]);
    }
);
$msg = $cmd->run(undef, $human, '*foo *bar hello');

$cmd->save(
    sub {
        my ($hamster, $human, $title, $content, $tags) = @_;

        is($title,   'Ho');
        is($content, 'How are you?');
    }
);
$msg = $cmd->run(undef, $human, 'Ho. How are you?');

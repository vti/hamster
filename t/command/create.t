use Test::More tests => 3;

use Hamster;
use Hamster::Human;
use AnyEvent::XMPP::IM::Message;

use_ok('Hamster::Command::Create');

my $cmd = Hamster::Command::Create->new;
ok($cmd);

my $hamster = Hamster->new;
my $human = Hamster::Human->new(jid => 'foo@bar.com');

my $input = AnyEvent::XMPP::IM::Message->new(body => 'Hello');

my $msg =
  $cmd->run($input, sub { is(shift->body, "Topic 'Hello' was created"); });

#$cmd->save(
    #sub {
        #my ($hamster, $human, $title, $content, $tags) = @_;

        #is($title,   'hello');
        #is($content, 'hello');
        #is_deeply($tags, [qw/foo bar/]);

        #return AnyEvent::XMPP::IM::Message->new(
            #to   => $human->jid,
            #body => 'Hello from save'
        #);
    #}
#);
#$msg = $cmd->run(undef, $human, '*foo *bar hello');
#is($msg->to,   'foo@bar.com');
#is($msg->body, 'Hello from save');

#$cmd->title_length(3);
#$cmd->save(
    #sub {
        #my ($hamster, $human, $title, $content, $tags) = @_;

        #is($title,   'hel...');
        #is($content, 'hello');
        #is_deeply($tags, [qw/foo bar/]);
    #}
#);
#$msg = $cmd->run(undef, $human, '*foo *bar hello');

#$cmd->save(
    #sub {
        #my ($hamster, $human, $title, $content, $tags) = @_;

        #is($title,   'Ho');
        #is($content, 'How are you?');
    #}
#);
#$msg = $cmd->run(undef, $human, 'Ho. How are you?');

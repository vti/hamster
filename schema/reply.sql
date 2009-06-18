DROP TABLE IF EXISTS `reply`;
CREATE TABLE `reply` (
 `topic_id` INTEGER NOT NULL,
 `seq`      INTEGER NOT NULL DEFAULT 1,
 `jid_id`   INTEGER NOT NULL,
 `addtime`  INTEGER NOT NULL,
 `body`     VARCHAR(40) NOT NULL,
 `resource` VARCHAR(1023),
 PRIMARY KEY(`topic_id`, `seq`)
);

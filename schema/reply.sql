DROP TABLE IF EXISTS `reply`;
CREATE TABLE `reply` (
 `topic_id`   INTEGER NOT NULL,
 `seq`        INTEGER NOT NULL DEFAULT 1,
 `human_id`   INTEGER NOT NULL,
 `parent_seq` INTEGER,
 `addtime`    INTEGER NOT NULL,
 `body`       VARCHAR(40) NOT NULL,
 `jid`        VARCHAR(1023) NOT NULL,
 `resource`   VARCHAR(1023),
 PRIMARY KEY(`topic_id`, `seq`)
);

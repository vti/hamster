DROP TABLE IF EXISTS `jid`;
CREATE TABLE `jid` (
 `id`       INTEGER PRIMARY KEY,
 `human_id` INTEGER NOT NULL,
 `jid`      VARCHAR(3071),
 UNIQUE(`jid`)
);

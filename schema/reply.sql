DROP TABLE IF EXISTS `reply`;
CREATE TABLE `reply` (
 `id`       INTEGER PRIMARY KEY,
 `addtime`  INTEGER NOT NULL,
 `reply_id` INTEGER,
 `topic_id` INTEGER NOT NULL,
 `body`     VARCHAR(40) NOT NULL,
 `resource` VARCHAR(1023)
);

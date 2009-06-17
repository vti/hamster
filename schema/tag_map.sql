DROP TABLE IF EXISTS `tag_map`;
CREATE TABLE `tag_map` (
 `tag_id`   INTEGER NOT NULL,
 `topic_id` INTEGER NOT NULL,
 PRIMARY KEY(`tag_id`, `topic_id`)
);

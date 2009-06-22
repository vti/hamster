DROP TABLE IF EXISTS `subscription`;
CREATE TABLE `subscription` (
 `master_type` CHAR(1) NOT NULL,
 `master_id`   INTEGER NOT NULL,
 `human_id`    INTEGER NOT NULL,
 PRIMARY KEY(`master_type`, `master_id`, `human_id`)
);

DROP TABLE IF EXISTS `tag`;
CREATE TABLE `tag` (
 `id`    INTEGER PRIMARY KEY,
 `title` VARCHAR(40) NOT NULL,
 UNIQUE(`title`)
);

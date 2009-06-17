DROP TABLE IF EXISTS `human`;
CREATE TABLE `human` (
 `id`      INTEGER PRIMARY KEY,
 `addtime` INTEGER NOT NULL,
 `nick`    VARCHAR(40),
 UNIQUE(`nick`)
);

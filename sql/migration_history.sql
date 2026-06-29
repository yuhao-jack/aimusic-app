-- 播放历史功能数据库迁移脚本
USE aimusic;

-- 播放历史表
CREATE TABLE IF NOT EXISTS `play_histories` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `user_id` bigint unsigned DEFAULT NULL COMMENT '用户ID',
  `song_id` bigint unsigned DEFAULT NULL COMMENT '歌曲ID',
  `played_at` bigint DEFAULT NULL COMMENT '播放时间戳',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_song_id` (`song_id`),
  KEY `idx_played_at` (`played_at`),
  KEY `idx_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='播放历史表';

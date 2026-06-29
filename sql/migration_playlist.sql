-- 歌单功能数据库迁移脚本
USE aimusic;

-- 歌单表
CREATE TABLE IF NOT EXISTS `playlists` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `user_id` bigint unsigned DEFAULT NULL COMMENT '所属用户ID',
  `name` varchar(64) DEFAULT NULL COMMENT '歌单名称',
  `description` varchar(255) DEFAULT NULL COMMENT '歌单描述',
  `cover` varchar(255) DEFAULT NULL COMMENT '封面图地址',
  `is_public` tinyint DEFAULT '0' COMMENT '是否公开：0私有 1公开',
  `song_count` int DEFAULT '0' COMMENT '歌曲数量',
  `play_count` int DEFAULT '0' COMMENT '播放次数',
  `like_count` int DEFAULT '0' COMMENT '点赞次数',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_is_public` (`is_public`),
  KEY `idx_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='歌单表';

-- 歌单歌曲关联表
CREATE TABLE IF NOT EXISTS `playlist_songs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `playlist_id` bigint unsigned DEFAULT NULL COMMENT '歌单ID',
  `song_id` bigint unsigned DEFAULT NULL COMMENT '歌曲ID',
  `sort_order` int DEFAULT '0' COMMENT '排序顺序',
  PRIMARY KEY (`id`),
  KEY `idx_playlist_id` (`playlist_id`),
  KEY `idx_song_id` (`song_id`),
  KEY `idx_deleted_at` (`deleted_at`),
  UNIQUE KEY `idx_playlist_song` (`playlist_id`, `song_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='歌单歌曲关联表';

-- 歌单点赞表
CREATE TABLE IF NOT EXISTS `playlist_likes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `playlist_id` bigint unsigned DEFAULT NULL COMMENT '歌单ID',
  `user_id` bigint unsigned DEFAULT NULL COMMENT '用户ID',
  PRIMARY KEY (`id`),
  KEY `idx_playlist_id` (`playlist_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_deleted_at` (`deleted_at`),
  UNIQUE KEY `idx_playlist_user` (`playlist_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='歌单点赞表';

-- 插入一些示例歌单数据
INSERT INTO `playlists` (`user_id`, `name`, `description`, `is_public`, `song_count`, `play_count`, `like_count`) VALUES
(0, 'AI创作精选', '人工智能创作的佳作', 1, 3, 128, 32),
(0, '热门榜单', '最火的歌曲都在这', 1, 3, 256, 64),
(0, '我的收藏', '我喜欢的音乐', 0, 2, 45, 8);

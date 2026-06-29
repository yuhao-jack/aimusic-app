-- 音色克隆功能数据库迁移脚本
USE aimusic;

-- 音色克隆表
CREATE TABLE IF NOT EXISTS `voice_clones` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `user_id` bigint unsigned DEFAULT NULL COMMENT '用户ID',
  `name` varchar(100) DEFAULT NULL COMMENT '音色名称',
  `description` text COMMENT '音色描述',
  `voice_type` varchar(50) DEFAULT NULL COMMENT '音色类型（original/cloned）',
  `status` varchar(20) DEFAULT 'pending' COMMENT '状态（pending/processing/completed/failed）',
  `progress` int DEFAULT 0 COMMENT '克隆进度 0-100',
  `error_msg` text COMMENT '错误信息',
  `audio_url` varchar(500) DEFAULT NULL COMMENT '上传的音频URL',
  `voice_url` varchar(500) DEFAULT NULL COMMENT '克隆后的音色URL',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='音色克隆表';

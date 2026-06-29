-- 数据库初始化脚本
CREATE DATABASE IF NOT EXISTS aimusic DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE aimusic;

-- 用户表
CREATE TABLE IF NOT EXISTS `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `open_id` varchar(64) DEFAULT NULL COMMENT '第三方登录唯一标识',
  `nickname` varchar(32) DEFAULT NULL COMMENT '用户昵称',
  `avatar` varchar(255) DEFAULT NULL COMMENT '头像地址',
  `phone` varchar(16) DEFAULT NULL COMMENT '手机号',
  `email` varchar(64) DEFAULT NULL COMMENT '邮箱',
  `password` varchar(255) DEFAULT NULL COMMENT '密码',
  `status` tinyint DEFAULT '0' COMMENT '用户状态：0正常 1禁用',
  `member_level` tinyint DEFAULT '0' COMMENT '会员等级：0普通 1普通会员 2高级会员',
  `member_expire_at` datetime DEFAULT NULL COMMENT '会员过期时间',
  `daily_generate_count` int DEFAULT '0' COMMENT '今日生成次数',
  `last_generate_date` varchar(10) DEFAULT NULL COMMENT '最后生成日期yyyy-mm-dd',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_open_id` (`open_id`),
  UNIQUE KEY `idx_phone` (`phone`),
  KEY `idx_status` (`status`),
  KEY `idx_member_level` (`member_level`),
  KEY `idx_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 歌曲表
CREATE TABLE IF NOT EXISTS `songs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `user_id` bigint unsigned DEFAULT NULL COMMENT '所属用户ID，官方内容为0',
  `title` varchar(128) DEFAULT NULL COMMENT '歌曲名称',
  `singer` varchar(64) DEFAULT NULL COMMENT '歌手名',
  `cover` varchar(255) DEFAULT NULL COMMENT '封面图地址',
  `audio_url` varchar(255) DEFAULT NULL COMMENT '音频文件地址',
  `lyric` text COMMENT '歌词内容',
  `style` varchar(32) DEFAULT NULL COMMENT '音乐风格',
  `emotion` varchar(32) DEFAULT NULL COMMENT '情绪标签',
  `duration` int DEFAULT NULL COMMENT '时长，单位秒',
  `play_count` int DEFAULT '0' COMMENT '播放次数',
  `like_count` int DEFAULT '0' COMMENT '点赞次数',
  `status` tinyint DEFAULT '0' COMMENT '状态：0审核中 1正常 2下架',
  `copyright_id` varchar(64) DEFAULT NULL COMMENT '版权唯一标识',
  `is_public` tinyint DEFAULT '1' COMMENT '是否公开：0私有 1公开',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_copyright_id` (`copyright_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_title` (`title`),
  KEY `idx_style` (`style`),
  KEY `idx_emotion` (`emotion`),
  KEY `idx_play_count` (`play_count`),
  KEY `idx_like_count` (`like_count`),
  KEY `idx_status` (`status`),
  KEY `idx_is_public` (`is_public`),
  KEY `idx_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='歌曲表';

-- 异步任务表
CREATE TABLE IF NOT EXISTS `async_tasks` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `task_type` tinyint DEFAULT NULL COMMENT '任务类型：1音乐生成 2音色训练 3MV渲染',
  `user_id` bigint unsigned DEFAULT NULL COMMENT '所属用户ID',
  `params` json DEFAULT NULL COMMENT '任务参数',
  `status` tinyint DEFAULT '0' COMMENT '状态：0等待中 1处理中 2成功 3失败',
  `progress` int DEFAULT '0' COMMENT '进度 0-100',
  `result` json DEFAULT NULL COMMENT '任务结果',
  `error_msg` varchar(255) DEFAULT NULL COMMENT '错误信息',
  PRIMARY KEY (`id`),
  KEY `idx_task_type` (`task_type`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='异步任务表';

-- 插入初始测试数据
INSERT INTO `songs` (`user_id`, `title`, `singer`, `cover`, `audio_url`, `lyric`, `style`, `emotion`, `duration`, `play_count`, `like_count`, `status`, `is_public`) VALUES
(0, 'AI创作的第一首歌', 'AI歌手', 'https://picsum.photos/200/200?random=1', 'https://demo.audio.com/test1.mp3', '[00:00.00]测试歌词\\n[00:03.00]第一句', '流行', '开心', 180, 100, 20, 1, 1),
(0, '电子音乐测试', '电音AI', 'https://picsum.photos/200/200?random=2', 'https://demo.audio.com/test2.mp3', '[00:00.00]电子音乐\\n[00:02.00]动感节奏', '电子', '热血', 200, 256, 45, 1, 1),
(0, '民谣小清新', '民谣AI', 'https://picsum.photos/200/200?random=3', 'https://demo.audio.com/test3.mp3', '[00:00.00]小清新民谣\\n[00:04.00]青春回忆', '民谣', '治愈', 220, 189, 32, 1, 1);

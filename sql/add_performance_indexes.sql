-- 性能优化索引建议
-- 为高频查询字段添加索引

-- 歌曲表索引
-- 用于推荐歌曲查询：WHERE status = 1 AND is_public = 1 ORDER BY play_count DESC
CREATE INDEX IF NOT EXISTS idx_songs_status_public_playcount ON songs(status, is_public, play_count DESC);

-- 用于每日推荐查询：WHERE status = 1 AND is_public = 1 ORDER BY RAND()
CREATE INDEX IF NOT EXISTS idx_songs_status_public ON songs(status, is_public);

-- 用于搜索查询：WHERE status = 1 AND is_public = 1 AND (title LIKE ? OR singer LIKE ?)
CREATE INDEX IF NOT EXISTS idx_songs_title_singer ON songs(title, singer);

-- 用于风格查询：WHERE status = 1 AND is_public = 1 AND style != ''
CREATE INDEX IF NOT EXISTS idx_songs_style ON songs(style);

-- 用于用户歌曲查询：WHERE user_id = ? AND status = 1 AND is_public = 1
CREATE INDEX IF NOT EXISTS idx_songs_user_status_public ON songs(user_id, status, is_public);

-- 房间表索引
-- 用于公开房间查询：WHERE status = 1 AND password = '' ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_rooms_status_password_created ON together_rooms(status, password, created_at DESC);

-- 用于用户房间查询：WHERE creator_id = ? AND status = 1
CREATE INDEX IF NOT EXISTS idx_rooms_creator_status ON together_rooms(creator_id, status);

-- 房间成员表索引
-- 用于房间成员查询：WHERE room_id = ?
CREATE INDEX IF NOT EXISTS idx_room_members_room_id ON room_members(room_id);

-- 用于用户房间查询：WHERE user_id = ?
CREATE INDEX IF NOT EXISTS idx_room_members_user_id ON room_members(user_id);

-- 复合索引用于统计成员数：WHERE room_id IN ? GROUP BY room_id
CREATE INDEX IF NOT EXISTS idx_room_members_room_user ON room_members(room_id, user_id);

-- 歌单表索引
-- 用于推荐歌单查询：WHERE is_public = 1 ORDER BY like_count DESC, play_count DESC
CREATE INDEX IF NOT EXISTS idx_playlists_public_like_play ON playlists(is_public, like_count DESC, play_count DESC);

-- 用于用户歌单查询：WHERE user_id = ? ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_playlists_user_created ON playlists(user_id, created_at DESC);

-- 点赞表索引
-- 用于检查用户是否已点赞：WHERE user_id = ? AND target_id = ? AND like_type = ?
CREATE INDEX IF NOT EXISTS idx_likes_user_target_type ON likes(user_id, target_id, like_type);

-- 评论表索引
-- 用于歌曲评论查询：WHERE song_id = ? AND parent_id = 0 ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_comments_song_parent_created ON comments(song_id, parent_id, created_at DESC);

-- 用户表索引
-- 用于创作明星查询：按作品数量排序
CREATE INDEX IF NOT EXISTS idx_users_id_nickname ON users(id, nickname);

-- 通知表索引
-- 用于用户通知查询：WHERE user_id = ? ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON notifications(user_id, created_at DESC);
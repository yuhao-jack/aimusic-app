package model

import "gorm.io/gorm"

// Playlist 歌单模型
type Playlist struct {
	gorm.Model
	UserID        uint   `gorm:"index;comment:所属用户ID" json:"user_id"`
	Name          string `gorm:"size:64;comment:歌单名称" json:"name"`
	Description   string `gorm:"size:255;comment:歌单描述" json:"description"`
	Cover         string `gorm:"size:255;comment:封面图地址" json:"cover"`
	IsPublic      int8   `gorm:"default:0;index;comment:是否公开：0私有 1公开" json:"is_public"`
	SongCount     int    `gorm:"default:0;comment:歌曲数量" json:"song_count"`
	PlayCount     int    `gorm:"default:0;comment:播放次数" json:"play_count"`
	LikeCount     int    `gorm:"default:0;comment:点赞次数" json:"like_count"`
	IsFeatured    bool   `gorm:"default:false;index;comment:是否精选" json:"is_featured"`
	FeaturedSort  int    `gorm:"default:0;comment:精选排序" json:"featured_sort"`
}

func (Playlist) TableName() string {
	return "playlists"
}

// PlaylistSong 歌单歌曲关联模型
type PlaylistSong struct {
	gorm.Model
	PlaylistID uint `gorm:"index;comment:歌单ID" json:"playlist_id"`
	SongID     uint `gorm:"index;comment:歌曲ID" json:"song_id"`
	SortOrder  int  `gorm:"default:0;comment:排序顺序" json:"sort_order"`
}

func (PlaylistSong) TableName() string {
	return "playlist_songs"
}

// PlaylistLike 歌单点赞模型
type PlaylistLike struct {
	gorm.Model
	PlaylistID uint `gorm:"index;comment:歌单ID" json:"playlist_id"`
	UserID     uint `gorm:"index;comment:用户ID" json:"user_id"`
}

func (PlaylistLike) TableName() string {
	return "playlist_likes"
}

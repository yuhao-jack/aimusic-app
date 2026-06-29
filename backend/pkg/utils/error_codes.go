package utils

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// 统一错误码定义
// 格式：模块代码 + 错误类型 + 序号
// 模块代码：10-用户, 20-音乐, 30-AI创作, 40-歌单, 50-动态, 60-会员, 70-系统

const (
	// 通用错误码
	CodeSuccess       = 0
	CodeBadRequest    = http.StatusBadRequest       // 400 - 参数错误
	CodeUnauthorized  = http.StatusUnauthorized      // 401 - 未授权
	CodeForbidden     = http.StatusForbidden         // 403 - 禁止访问
	CodeNotFound      = http.StatusNotFound          // 404 - 资源不存在
	CodeInternalError = http.StatusInternalServerError // 500 - 服务器内部错误

	// 用户模块错误码 (10xxx)
	CodeUserNotFound     = 10001 // 用户不存在
	CodeUserPasswordWrong = 10002 // 密码错误
	CodeUserDisabled     = 10003 // 用户已禁用
	CodeUserAlreadyExists = 10004 // 用户已存在
	CodeUserRegisterFail = 10005 // 注册失败
	CodeUserLoginFail    = 10006 // 登录失败
	CodeUserTokenInvalid = 10007 // 令牌无效
	CodeUserTokenExpired = 10008 // 令牌过期
	CodeUserUpdateFail   = 10009 // 更新用户信息失败
	CodeUserFollowSelf   = 10010 // 不能关注自己
	CodeUserAlreadyFollow = 10011 // 已关注该用户

	// 音乐模块错误码 (20xxx)
	CodeMusicNotFound      = 20001 // 歌曲不存在
	CodeMusicNotAccessible = 20002 // 歌曲不可访问
	CodeMusicSearchFail    = 20003 // 搜索失败
	CodeMusicQueryFail     = 20004 // 查询失败
	CodeMusicUpdateFail    = 20005 // 更新失败
	CodeMusicLikeFail      = 20006 // 点赞失败
	CodeMusicUnlikeFail    = 20007 // 取消点赞失败
	CodeCommentAddFail     = 20008 // 添加评论失败
	CodeCommentQueryFail   = 20009 // 查询评论失败
	CodeCommentTooLong     = 20010 // 评论内容过长

	// 一起听模块错误码 (25xxx)
	CodeRoomNotFound      = 25001 // 房间不存在
	CodeRoomAlreadyExists = 25002 // 已有进行中的房间
	CodeRoomFull          = 25003 // 房间已满
	CodeRoomPasswordWrong = 25004 // 房间密码错误
	CodeRoomCreateFail    = 25005 // 创建房间失败
	CodeRoomJoinFail      = 25006 // 加入房间失败
	CodeRoomLeaveFail     = 25007 // 离开房间失败
	CodeRoomUpdateFail    = 25008 // 更新房间失败
	CodeRoomKickFail      = 25009 // 踢出成员失败
	CodeRoomCodeGenerateFail = 25010 // 生成房间码失败
	CodeRoomNotCreator    = 25011 // 不是房主
	CodeRoomKickSelf      = 25012 // 不能踢出自己

	// AI创作模块错误码 (30xxx)
	CodeAIGenerateFail   = 30001 // 生成失败
	CodeAITaskNotFound   = 30002 // 任务不存在
	CodeAIQuotaExhausted = 30003 // AI配额已用完
	CodeAIOptimizeFail   = 30004 // 优化失败

	// 歌单模块错误码 (40xxx)
	CodePlaylistNotFound     = 40001 // 歌单不存在
	CodePlaylistCreateFail   = 40002 // 创建歌单失败
	CodePlaylistUpdateFail   = 40003 // 更新歌单失败
	CodePlaylistDeleteFail   = 40004 // 删除歌单失败
	CodePlaylistAddSongFail  = 40005 // 添加歌曲失败
	CodePlaylistRemoveSongFail = 40006 // 移除歌曲失败

	// 动态模块错误码 (50xxx)
	CodePostNotFound     = 50001 // 动态不存在
	CodePostCreateFail   = 50002 // 创建动态失败
	CodePostDeleteFail   = 50003 // 删除动态失败
	CodePostLikeFail     = 50004 // 点赞失败
	CodePostCommentFail  = 50005 // 评论失败

	// 会员模块错误码 (60xxx)
	CodeMembershipBuyFail    = 60001 // 购买失败
	CodeMembershipCheckInFail = 60002 // 签到失败
	CodeMembershipNotFound   = 60003 // 会员信息不存在

	// 通知模块错误码 (70xxx)
	CodeNotificationQueryFail = 70001 // 查询通知失败
	CodeNotificationReadFail  = 70002 // 标记已读失败

	// 文件上传模块错误码 (80xxx)
	CodeUploadFail     = 80001 // 上传失败
	CodeUploadSizeExceed = 80002 // 文件大小超限
	CodeUploadTypeWrong  = 80003 // 文件类型错误

	// 音色克隆模块错误码 (90xxx)
	CodeVoiceCloneNotFound   = 90001 // 音色克隆不存在
	CodeVoiceCloneCreateFail = 90002 // 创建失败
	CodeVoiceCloneUpdateFail = 90003 // 更新失败
	CodeVoiceCloneDeleteFail = 90004 // 删除失败

	// 日记模块错误码 (100xxx)
	CodeDiaryNotFound   = 100001 // 日记不存在
	CodeDiaryCreateFail = 100002 // 创建失败
	CodeDiaryDeleteFail = 100003 // 删除失败
)

// ErrorMessage 错误码对应的中文消息
var ErrorMessage = map[int]string{
	CodeSuccess:       "成功",
	CodeBadRequest:    "参数错误",
	CodeUnauthorized:  "未授权",
	CodeForbidden:     "禁止访问",
	CodeNotFound:      "资源不存在",
	CodeInternalError: "服务器内部错误",

	// 用户模块
	CodeUserNotFound:      "用户不存在",
	CodeUserPasswordWrong: "密码错误",
	CodeUserDisabled:      "用户已禁用",
	CodeUserAlreadyExists: "用户已存在",
	CodeUserRegisterFail:  "注册失败",
	CodeUserLoginFail:     "登录失败",
	CodeUserTokenInvalid:  "令牌无效",
	CodeUserTokenExpired:  "令牌过期",
	CodeUserUpdateFail:    "更新用户信息失败",
	CodeUserFollowSelf:    "不能关注自己",
	CodeUserAlreadyFollow: "已关注该用户",

	// 音乐模块
	CodeMusicNotFound:      "歌曲不存在",
	CodeMusicNotAccessible: "歌曲不可访问",
	CodeMusicSearchFail:    "搜索失败",
	CodeMusicQueryFail:     "查询失败",
	CodeMusicUpdateFail:    "更新失败",
	CodeMusicLikeFail:      "点赞失败",
	CodeMusicUnlikeFail:    "取消点赞失败",
	CodeCommentAddFail:     "添加评论失败",
	CodeCommentQueryFail:   "查询评论失败",
	CodeCommentTooLong:     "评论内容不能超过1000字",

	// 一起听模块
	CodeRoomNotFound:       "房间不存在或已结束",
	CodeRoomAlreadyExists:  "你已有进行中的房间",
	CodeRoomFull:           "房间已满",
	CodeRoomPasswordWrong:  "密码错误",
	CodeRoomCreateFail:     "创建房间失败",
	CodeRoomJoinFail:       "加入房间失败",
	CodeRoomLeaveFail:      "离开房间失败",
	CodeRoomUpdateFail:     "更新房间失败",
	CodeRoomKickFail:       "踢出成员失败",
	CodeRoomCodeGenerateFail: "生成房间码失败",
	CodeRoomNotCreator:     "只有房主可以操作",
	CodeRoomKickSelf:       "不能踢出自己",

	// AI创作模块
	CodeAIGenerateFail:   "生成失败",
	CodeAITaskNotFound:   "任务不存在",
	CodeAIQuotaExhausted: "AI配额已用完",
	CodeAIOptimizeFail:   "优化失败",

	// 歌单模块
	CodePlaylistNotFound:       "歌单不存在",
	CodePlaylistCreateFail:     "创建歌单失败",
	CodePlaylistUpdateFail:     "更新歌单失败",
	CodePlaylistDeleteFail:     "删除歌单失败",
	CodePlaylistAddSongFail:    "添加歌曲失败",
	CodePlaylistRemoveSongFail: "移除歌曲失败",

	// 动态模块
	CodePostNotFound:   "动态不存在",
	CodePostCreateFail: "创建动态失败",
	CodePostDeleteFail: "删除动态失败",
	CodePostLikeFail:   "点赞失败",
	CodePostCommentFail: "评论失败",

	// 会员模块
	CodeMembershipBuyFail:     "购买失败",
	CodeMembershipCheckInFail: "签到失败",
	CodeMembershipNotFound:    "会员信息不存在",

	// 通知模块
	CodeNotificationQueryFail: "查询通知失败",
	CodeNotificationReadFail:  "标记已读失败",

	// 文件上传模块
	CodeUploadFail:       "上传失败",
	CodeUploadSizeExceed: "文件大小超限",
	CodeUploadTypeWrong:  "文件类型错误",

	// 音色克隆模块
	CodeVoiceCloneNotFound:   "音色克隆不存在",
	CodeVoiceCloneCreateFail: "创建失败",
	CodeVoiceCloneUpdateFail: "更新失败",
	CodeVoiceCloneDeleteFail: "删除失败",

	// 日记模块
	CodeDiaryNotFound:   "日记不存在",
	CodeDiaryCreateFail: "创建失败",
	CodeDiaryDeleteFail: "删除失败",
}

// GetErrorMessage 获取错误码对应的中文消息
func GetErrorMessage(code int) string {
	if msg, ok := ErrorMessage[code]; ok {
		return msg
	}
	return "未知错误"
}

// FailWithCode 使用错误码返回失败响应
func FailWithCode(c *gin.Context, code int) {
	httpCode := code
	// 如果是业务错误码（大于10000），使用400作为HTTP状态码
	if code > 10000 {
		httpCode = CodeBadRequest
	}
	c.JSON(httpCode, Response{
		Code: code,
		Msg:  GetErrorMessage(code),
	})
}

// FailWithCodeAndMsg 使用错误码和自定义消息返回失败响应
func FailWithCodeAndMsg(c *gin.Context, code int, msg string) {
	httpCode := code
	if code > 10000 {
		httpCode = CodeBadRequest
	}
	c.JSON(httpCode, Response{
		Code: code,
		Msg:  msg,
	})
}

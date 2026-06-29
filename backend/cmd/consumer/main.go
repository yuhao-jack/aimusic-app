package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/config"
	"github.com/go-redis/redis/v8"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/ai"
)

var aiService ai.AIService

func main() {
	log.Println("=== AI Music Consumer ===")

	// 1. 初始化配置
	if err := config.InitConfig(); err != nil {
		log.Fatalf("Init config failed: %v", err)
	}
	log.Println("Config initialized successfully")

	// 2. 初始化MySQL
	if err := db.InitMySQL(); err != nil {
		log.Fatalf("Init MySQL failed: %v", err)
	}
	log.Println("MySQL initialized successfully")

	// 3. 初始化Redis
	if err := db.InitRedis(); err != nil {
		log.Fatalf("Init Redis failed: %v", err)
	}
	log.Println("Redis initialized successfully")

	// 4. 初始化AI服务
	aiService = ai.NewAIService(&config.AppConfig)
	log.Println("AI Service initialized successfully")

	// 5. 开始消费任务
	log.Println("Starting to consume tasks...")
	consumeTasks()
}

func consumeTasks() {
	ctx := context.Background()

	// 定义所有需要消费的流
	streams := []struct {
		name         string
		group        string
		processFunc  func(ctx context.Context, values map[string]interface{}) error
	}{
		{"music_generate_tasks", "music_consumers", processTask},
		{"voice_clone_tasks", "voice_consumers", processVoiceCloneTask},
		{"mv_generate_tasks", "mv_consumers", processMVGenerateTaskFromStream},
	}

	// 为每个流创建消费者组
	for _, s := range streams {
		err := db.Redis.XGroupCreateMkStream(ctx, s.name, s.group, "0").Err()
		if err != nil && err.Error() != "BUSYGROUP Consumer Group name already exists" {
			log.Printf("Create consumer group for %s failed: %v", s.name, err)
		}
	}

	log.Println("Consumer started, waiting for tasks...")

	// 并行消费所有流
	for _, s := range streams {
		go func(stream struct {
			name         string
			group        string
			processFunc  func(ctx context.Context, values map[string]interface{}) error
		}) {
			consumerName := stream.group + "-1"
			log.Printf("Listening on stream: %s (group: %s)", stream.name, stream.group)
			for {
				result, err := db.Redis.XReadGroup(ctx, &redis.XReadGroupArgs{
					Group:    stream.group,
					Consumer: consumerName,
					Streams:  []string{stream.name, ">"},
					Count:    1,
					Block:    0,
				}).Result()
				if err != nil {
					log.Printf("Read from stream %s failed: %v", stream.name, err)
					time.Sleep(2 * time.Second)
					continue
				}
				for _, streamResult := range result {
					for _, msg := range streamResult.Messages {
						log.Printf("Received task from %s: %+v", stream.name, msg.Values)
						if err := stream.processFunc(ctx, msg.Values); err != nil {
							log.Printf("Process task from %s failed: %v", stream.name, err)
						}
						db.Redis.XAck(ctx, stream.name, stream.group, msg.ID)
					}
				}
			}
		}(s)
	}

	// 阻塞主线程
	select {}
}

func processTask(ctx context.Context, values map[string]interface{}) error {
	// 解析任务参数
	taskIDStr, ok := values["task_id"].(string)
	if !ok {
		return fmt.Errorf("task_id not found or invalid")
	}

	var taskID uint
	if _, err := fmt.Sscanf(taskIDStr, "%d", &taskID); err != nil {
		return fmt.Errorf("parse task_id failed: %v", err)
	}

	// 查询任务
	var task model.AsyncTask
	if err := db.DB.First(&task, taskID).Error; err != nil {
		return fmt.Errorf("find task failed: %v", err)
	}

	log.Printf("Processing task: ID=%d, Type=%d", task.ID, task.TaskType)

	// 更新任务状态为处理中
	task.Status = model.TaskStatusRunning
	task.Progress = 0
	if err := db.DB.Save(&task).Error; err != nil {
		return fmt.Errorf("update task status failed: %v", err)
	}

	// 根据任务类型处理
	switch task.TaskType {
	case model.TaskTypeMusicGenerate:
		return processMusicGenerateTask(&task)
	case model.TaskTypeVoiceTrain:
		return processVoiceTrainTask(&task)
	case model.TaskTypeMVGenerate:
		return processMVGenerateTask(&task)
	default:
		return fmt.Errorf("unknown task type: %d", task.TaskType)
	}
}

func processMusicGenerateTask(task *model.AsyncTask) error {
	log.Println("Processing music generation task...")

	// 解析任务参数
	var params model.GenerateSongRequest
	if err := json.Unmarshal(task.Params, &params); err != nil {
		updateTaskError(task, "Invalid task parameters")
		return fmt.Errorf("parse params failed: %v", err)
	}

	// 调用AI服务生成歌曲
	updateTaskProgress(task, 10, "正在提交到AI服务...")
	
	aiTaskID, err := aiService.GenerateSong(
		params.Lyric,
		params.Style,
		params.Emotion,
		params.VoiceID,
		params.Duration,
		params.Title,
	)
	if err != nil {
		updateTaskError(task, "AI service error: "+err.Error())
		return fmt.Errorf("generate song failed: %v", err)
	}

	log.Printf("AI task submitted, task_id: %s", aiTaskID)

	// 轮询AI任务进度
	updateTaskProgress(task, 20, "AI正在生成...")
	
	maxPolls := 180 // 最多轮询180次（6分钟）
	for i := 0; i < maxPolls; i++ {
		progress, err := aiService.GetSongGenerationProgress(aiTaskID)
		if err != nil {
			log.Printf("Poll progress error: %v", err)
			time.Sleep(2 * time.Second)
			continue
		}

		// 更新进度
		if progress.Progress > 0 {
			updateTaskProgress(task, progress.Progress, getProgressMessage(progress.Progress))
		}

		// 检查状态
		if progress.Status == "completed" {
			// 完成
			updateTaskProgress(task, 100, "Completed!")
			
			result := map[string]interface{}{
				"song_id":    aiTaskID,
				"title":      params.Title,
				"duration":   params.Duration,
				"audio_url":  progress.AudioURL,
				"cover_url":  progress.CoverURL,
				"created_at": time.Now().Format(time.RFC3339),
			}
			resultJSON, _ := json.Marshal(result)
			
			task.Status = model.TaskStatusSuccess
			task.Result = resultJSON
			if err := db.DB.Save(task).Error; err != nil {
				return fmt.Errorf("update task success failed: %v", err)
			}
			
			log.Printf("Music generation task completed: ID=%d", task.ID)
			return nil
			
		} else if progress.Status == "failed" {
			// 失败
			errMsg := progress.ErrorMsg
			if errMsg == "" {
				errMsg = "AI generation failed"
			}
			updateTaskError(task, errMsg)
			return fmt.Errorf("AI generation failed: %s", errMsg)
		}

		time.Sleep(2 * time.Second)
	}

	// 超时
	updateTaskError(task, "Generation timeout")
	return fmt.Errorf("generation timeout")
}

func getProgressMessage(progress int) string {
	switch {
	case progress < 25:
		return "正在处理歌词..."
	case progress < 50:
		return "正在创作旋律..."
	case progress < 75:
		return "正在生成人声..."
	case progress < 100:
		return "正在混音和母带处理..."
	default:
		return "完成！"
	}
}

func processVoiceTrainTask(task *model.AsyncTask) error {
	log.Println("Processing voice training task...")

	// 更新状态为处理中
	updateTaskProgress(task, 10, "音色训练准备中...")

	// 模拟训练过程：分阶段更新进度
	stages := []struct {
		progress int
		message  string
	}{
		{20, "正在分析音频特征..."},
		{40, "正在提取音色参数..."},
		{60, "正在训练音色模型..."},
		{80, "正在优化音色质量..."},
		{95, "正在生成音色文件..."},
	}

	for _, stage := range stages {
		time.Sleep(3 * time.Second) // 模拟耗时
		updateTaskProgress(task, stage.progress, stage.message)
	}

	// 模拟训练完成，更新VoiceClone状态
	var params map[string]interface{}
	if err := json.Unmarshal(task.Params, &params); err == nil {
		if voiceID, ok := params["voice_id"].(float64); ok {
			db.DB.Model(&model.VoiceClone{}).Where("id = ?", uint(voiceID)).Updates(map[string]interface{}{
				"status":     "completed",
				"progress":   100,
				"voice_url":  "/uploads/voices/cloned_voice_" + fmt.Sprintf("%d", uint(voiceID)) + ".bin",
			})
		}
	}

	// 任务完成
	task.Status = model.TaskStatusSuccess
	task.Progress = 100
	result := map[string]interface{}{
		"message": "音色训练完成",
	}
	resultJSON, _ := json.Marshal(result)
	task.Result = resultJSON
	if err := db.DB.Save(task).Error; err != nil {
		return fmt.Errorf("update task success failed: %v", err)
	}

	log.Printf("Voice training task completed: ID=%d", task.ID)
	return nil
}

func processMVGenerateTask(task *model.AsyncTask) error {
	log.Println("Processing MV generation task...")

	// 更新状态为处理中
	updateTaskProgress(task, 10, "MV生成准备中...")

	// 模拟MV生成过程：分阶段更新进度
	stages := []struct {
		progress int
		message  string
	}{
		{20, "正在解析歌曲信息..."},
		{40, "正在生成MV画面..."},
		{60, "正在合成视频片段..."},
		{80, "正在添加特效和转场..."},
		{95, "正在渲染最终MV..."},
	}

	for _, stage := range stages {
		time.Sleep(3 * time.Second) // 模拟耗时
		updateTaskProgress(task, stage.progress, stage.message)
	}

	// 模拟生成完成
	task.Status = model.TaskStatusSuccess
	task.Progress = 100
	result := map[string]interface{}{
		"message":  "MV生成完成",
		"mv_url":   "/uploads/mv/generated_mv.mp4",
	}
	resultJSON, _ := json.Marshal(result)
	task.Result = resultJSON
	if err := db.DB.Save(task).Error; err != nil {
		return fmt.Errorf("update task success failed: %v", err)
	}

	log.Printf("MV generation task completed: ID=%d", task.ID)
	return nil
}

// processVoiceCloneTask 从Redis Stream消费音色克隆任务
func processVoiceCloneTask(ctx context.Context, values map[string]interface{}) error {
	taskIDStr, ok := values["task_id"].(string)
	if !ok {
		return fmt.Errorf("task_id not found in voice_clone_tasks")
	}

	var taskID uint
	if _, err := fmt.Sscanf(taskIDStr, "%d", &taskID); err != nil {
		return fmt.Errorf("parse task_id failed: %v", err)
	}

	// 查询对应的异步任务记录
	var task model.AsyncTask
	if err := db.DB.Where("id = ? AND task_type = ?", taskID, model.TaskTypeVoiceTrain).First(&task).Error; err != nil {
		// 如果没有异步任务记录，直接处理VoiceClone
		log.Printf("No async task found for voice_clone %d, skipping", taskID)
		return nil
	}

	return processVoiceTrainTask(&task)
}

// processMVGenerateTaskFromStream 从Redis Stream消费MV生成任务
func processMVGenerateTaskFromStream(ctx context.Context, values map[string]interface{}) error {
	taskIDStr, ok := values["task_id"].(string)
	if !ok {
		return fmt.Errorf("task_id not found in mv_generate_tasks")
	}

	var taskID uint
	if _, err := fmt.Sscanf(taskIDStr, "%d", &taskID); err != nil {
		return fmt.Errorf("parse task_id failed: %v", err)
	}

	// 查询对应的异步任务记录
	var task model.AsyncTask
	if err := db.DB.Where("id = ? AND task_type = ?", taskID, model.TaskTypeMVGenerate).First(&task).Error; err != nil {
		log.Printf("No async task found for mv_generate %d, skipping", taskID)
		return nil
	}

	return processMVGenerateTask(&task)
}

func updateTaskProgress(task *model.AsyncTask, progress int, message string) {
	task.Progress = progress
	if err := db.DB.Model(task).Updates(map[string]interface{}{
		"progress": progress,
		"status":   model.TaskStatusRunning,
	}).Error; err != nil {
		log.Printf("Update task progress failed: %v", err)
	}
	log.Printf("Task %d progress: %d%% - %s", task.ID, progress, message)
}

func updateTaskError(task *model.AsyncTask, errMsg string) {
	task.Status = model.TaskStatusFailed
	task.ErrorMsg = errMsg
	if err := db.DB.Save(task).Error; err != nil {
		log.Printf("Update task error failed: %v", err)
	}
}

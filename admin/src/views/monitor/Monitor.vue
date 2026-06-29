<template>
  <div>
    <h2 style="margin-bottom: 20px;">实时监控</h2>
    
    <!-- 统计卡片 -->
    <el-row :gutter="20" style="margin-bottom: 20px;">
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #409eff;">
              <el-icon><User /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.online_users }}</div>
              <div class="stat-label">当前在线用户</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #67c23a;">
              <el-icon><MagicStick /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.ai_generations }}</div>
              <div class="stat-label">今日AI生成次数</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #e6a23c;">
              <el-icon><UserFilled /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.new_users }}</div>
              <div class="stat-label">今日新增用户</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #f56c6c;">
              <el-icon><Coin /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ formatRevenue(stats.revenue) }}</div>
              <div class="stat-label">今日收入</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20">
      <!-- 请求量趋势 -->
      <el-col :span="14">
        <el-card>
          <template #header>
            <span>最近1小时请求量趋势</span>
          </template>
          <div class="chart-container">
            <div class="bar-chart">
              <div v-for="(item, index) in stats.request_trend" :key="index" class="bar-item">
                <div class="bar-wrapper">
                  <div class="bar" :style="{ height: getBarHeight(item.count) + '%' }"></div>
                </div>
                <div class="bar-label">{{ item.time }}</div>
              </div>
            </div>
            <div class="chart-y-axis">
              <span>{{ maxCount }}</span>
              <span>{{ Math.floor(maxCount / 2) }}</span>
              <span>0</span>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- 最近告警 -->
      <el-col :span="10">
        <el-card>
          <template #header>
            <span>最近告警</span>
          </template>
          <div v-if="stats.recent_alerts && stats.recent_alerts.length > 0">
            <div v-for="alert in stats.recent_alerts" :key="alert.id" class="alert-item">
              <div class="alert-header">
                <el-tag :type="levelTagMap[alert.level]" size="small">{{ levelMap[alert.level] }}</el-tag>
                <span class="alert-type">{{ typeMap[alert.type] || alert.type }}</span>
                <el-tag :type="alert.status === 0 ? 'danger' : 'success'" size="small" style="margin-left: auto;">
                  {{ alert.status === 0 ? '未处理' : '已处理' }}
                </el-tag>
              </div>
              <div class="alert-message">{{ alert.message }}</div>
              <div class="alert-time">{{ alert.created_at }}</div>
            </div>
          </div>
          <el-empty v-else description="暂无告警" />
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { User, MagicStick, UserFilled, Coin } from '@element-plus/icons-vue'
import axios from 'axios'

// 类型和级别映射
const typeMap = { rate_limit: '限流告警', quota_abuse: '配额滥用', ip_abuse: 'IP滥用' }
const levelMap = { 1: '低', 2: '中', 3: '高' }
const levelTagMap = { 1: 'info', 2: 'warning', 3: 'danger' }

const stats = ref({
  online_users: 0,
  ai_generations: 0,
  new_users: 0,
  revenue: 0,
  request_trend: [],
  recent_alerts: []
})

// 计算最大请求数用于柱状图高度
const maxCount = computed(() => {
  if (!stats.value.request_trend || stats.value.request_trend.length === 0) return 1
  const max = Math.max(...stats.value.request_trend.map(item => item.count))
  return max > 0 ? max : 1
})

// 计算柱状图高度百分比
const getBarHeight = (count) => {
  return (count / maxCount.value) * 100
}

// 格式化收入（分转元）
const formatRevenue = (cents) => {
  return (cents / 100).toFixed(2) + '元'
}

// 加载数据
const loadData = async () => {
  try {
    const res = await axios.get('/api/admin/monitor/stats')
    if (res.data.code === 200) {
      stats.value = res.data.data
    }
  } catch (err) {
    console.error(err)
  }
}

// 自动刷新（每30秒）
let refreshTimer = null
onMounted(() => {
  loadData()
  refreshTimer = setInterval(loadData, 30000)
})
</script>

<style scoped>
.stat-card {
  display: flex;
  align-items: center;
  padding: 10px 0;
}

.stat-icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 24px;
}

.stat-info {
  margin-left: 16px;
}

.stat-value {
  font-size: 28px;
  font-weight: bold;
  color: #303133;
}

.stat-label {
  font-size: 14px;
  color: #909399;
  margin-top: 4px;
}

.chart-container {
  display: flex;
  height: 200px;
}

.bar-chart {
  flex: 1;
  display: flex;
  align-items: flex-end;
  gap: 4px;
  padding-bottom: 24px;
  position: relative;
}

.bar-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.bar-wrapper {
  width: 100%;
  height: 160px;
  display: flex;
  align-items: flex-end;
}

.bar {
  width: 100%;
  background: linear-gradient(180deg, #409eff 0%, #79bbff 100%);
  border-radius: 4px 4px 0 0;
  min-height: 2px;
  transition: height 0.3s;
}

.bar-label {
  font-size: 10px;
  color: #909399;
  margin-top: 4px;
  white-space: nowrap;
}

.chart-y-axis {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding-bottom: 28px;
  width: 40px;
  text-align: right;
  font-size: 10px;
  color: #909399;
}

.alert-item {
  padding: 12px 0;
  border-bottom: 1px solid #ebeef5;
}

.alert-item:last-child {
  border-bottom: none;
}

.alert-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
}

.alert-type {
  font-size: 13px;
  color: #606266;
}

.alert-message {
  font-size: 13px;
  color: #303133;
  margin-bottom: 4px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.alert-time {
  font-size: 12px;
  color: #909399;
}
</style>

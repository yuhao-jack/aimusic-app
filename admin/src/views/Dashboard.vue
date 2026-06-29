<template>
  <div class="dashboard">
    <div class="dashboard-header">
      <h2>数据面板</h2>
      <div class="time-filter">
        <el-radio-group v-model="trendDays" size="small" @change="loadTrend">
          <el-radio-button :value="7">近7天</el-radio-button>
          <el-radio-button :value="30">近30天</el-radio-button>
          <el-radio-button :value="90">近90天</el-radio-button>
        </el-radio-group>
        <el-button size="small" @click="loadAll" :loading="loading" style="margin-left: 12px;">
          <el-icon><Refresh /></el-icon> 刷新
        </el-button>
      </div>
    </div>

    <!-- 总数统计 -->
    <el-row :gutter="16" class="kpi-row">
      <el-col :xs="12" :sm="8" :md="4" v-for="item in totalCards" :key="item.key">
        <el-card shadow="hover" class="kpi-card">
          <div class="kpi-value" :style="{ color: item.color }">{{ formatNum(stats.totals?.[item.key]) }}</div>
          <div class="kpi-label">{{ item.label }}</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 今日新增 -->
    <el-row :gutter="16" class="kpi-row">
      <el-col :xs="12" :sm="8" :md="4" v-for="item in todayCards" :key="item.key">
        <el-card shadow="hover" class="kpi-card today">
          <div class="kpi-value today-value">+{{ formatNum(stats.today?.[item.key]) }}</div>
          <div class="kpi-label">今日{{ item.label }}</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 本周/本月 + 商业化 + AI指标 -->
    <el-row :gutter="16" class="section-row">
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="info-card">
          <template #header><span>本周新增</span></template>
          <div class="info-grid">
            <div class="info-item">
              <span class="info-num">{{ formatNum(stats.this_week?.new_users) }}</span>
              <span class="info-desc">用户</span>
            </div>
            <div class="info-item">
              <span class="info-num">{{ formatNum(stats.this_week?.new_songs) }}</span>
              <span class="info-desc">歌曲</span>
            </div>
            <div class="info-item">
              <span class="info-num">{{ formatNum(stats.this_week?.new_ai_tasks) }}</span>
              <span class="info-desc">AI任务</span>
            </div>
            <div class="info-item">
              <span class="info-num">{{ formatNum(stats.this_week?.new_posts) }}</span>
              <span class="info-desc">动态</span>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="info-card">
          <template #header><span>本月新增</span></template>
          <div class="info-grid">
            <div class="info-item">
              <span class="info-num">{{ formatNum(stats.this_month?.new_users) }}</span>
              <span class="info-desc">用户</span>
            </div>
            <div class="info-item">
              <span class="info-num">{{ formatNum(stats.this_month?.new_songs) }}</span>
              <span class="info-desc">歌曲</span>
            </div>
            <div class="info-item">
              <span class="info-num">{{ formatNum(stats.this_month?.new_ai_tasks) }}</span>
              <span class="info-desc">AI任务</span>
            </div>
            <div class="info-item">
              <span class="info-num">{{ formatNum(stats.this_month?.new_posts) }}</span>
              <span class="info-desc">动态</span>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="info-card">
          <template #header><span>商业化指标</span></template>
          <div class="info-grid">
            <div class="info-item">
              <span class="info-num">¥{{ formatMoney(stats.commercial?.today_revenue) }}</span>
              <span class="info-desc">今日收入</span>
            </div>
            <div class="info-item">
              <span class="info-num">¥{{ formatMoney(stats.commercial?.month_revenue) }}</span>
              <span class="info-desc">本月收入</span>
            </div>
            <div class="info-item">
              <span class="info-num">{{ formatNum(stats.commercial?.vip_count) }}</span>
              <span class="info-desc">VIP会员</span>
            </div>
            <div class="info-item">
              <span class="info-num">{{ formatNum(stats.commercial?.svip_count) }}</span>
              <span class="info-desc">SVIP会员</span>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="info-card">
          <template #header><span>AI任务状态</span></template>
          <div class="info-grid">
            <div class="info-item">
              <span class="info-num">{{ stats.ai?.success_rate || '0' }}%</span>
              <span class="info-desc">成功率</span>
            </div>
            <div class="info-item">
              <span class="info-num">{{ formatNum(stats.ai?.pending_tasks) }}</span>
              <span class="info-desc">等待处理</span>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 趋势图 -->
    <el-row :gutter="16" class="section-row">
      <el-col :xs="24" :md="12">
        <el-card shadow="hover">
          <template #header><span>用户增长趋势</span></template>
          <v-chart class="chart" :option="userTrendOption" autoresize />
        </el-card>
      </el-col>
      <el-col :xs="24" :md="12">
        <el-card shadow="hover">
          <template #header><span>歌曲增长趋势</span></template>
          <v-chart class="chart" :option="songTrendOption" autoresize />
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="16" class="section-row">
      <el-col :xs="24" :md="12">
        <el-card shadow="hover">
          <template #header><span>AI使用趋势</span></template>
          <v-chart class="chart" :option="aiTrendOption" autoresize />
        </el-card>
      </el-col>
      <el-col :xs="24" :md="12">
        <el-card shadow="hover">
          <template #header><span>动态增长趋势</span></template>
          <v-chart class="chart" :option="postTrendOption" autoresize />
        </el-card>
      </el-col>
    </el-row>

    <!-- 分布图 -->
    <el-row :gutter="16" class="section-row">
      <el-col :xs="24" :md="8">
        <el-card shadow="hover">
          <template #header><span>歌曲风格分布</span></template>
          <v-chart class="chart" :option="styleDistOption" autoresize />
        </el-card>
      </el-col>
      <el-col :xs="24" :md="8">
        <el-card shadow="hover">
          <template #header><span>情绪分布</span></template>
          <v-chart class="chart" :option="emotionDistOption" autoresize />
        </el-card>
      </el-col>
      <el-col :xs="24" :md="8">
        <el-card shadow="hover">
          <template #header><span>会员等级分布</span></template>
          <v-chart class="chart" :option="memberDistOption" autoresize />
        </el-card>
      </el-col>
    </el-row>

    <!-- 排行榜 -->
    <el-row :gutter="16" class="section-row">
      <el-col :xs="24" :md="8">
        <el-card shadow="hover">
          <template #header><span>热门歌曲 Top10</span></template>
          <div class="rank-list">
            <div v-for="(item, i) in rankings.hot_songs" :key="item.id" class="rank-item">
              <span class="rank-num" :class="{ 'top3': i < 3 }">{{ i + 1 }}</span>
              <span class="rank-title">{{ item.title }}</span>
              <span class="rank-count">{{ formatNum(item.play_count) }}次播放</span>
            </div>
            <el-empty v-if="!rankings.hot_songs?.length" description="暂无数据" :image-size="60" />
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :md="8">
        <el-card shadow="hover">
          <template #header><span>活跃用户 Top10</span></template>
          <div class="rank-list">
            <div v-for="(item, i) in rankings.active_users" :key="item.id" class="rank-item">
              <span class="rank-num" :class="{ 'top3': i < 3 }">{{ i + 1 }}</span>
              <span class="rank-title">{{ item.nickname }}</span>
              <span class="rank-count">{{ item.song_count }}歌/{{ item.post_count }}帖</span>
            </div>
            <el-empty v-if="!rankings.active_users?.length" description="暂无数据" :image-size="60" />
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :md="8">
        <el-card shadow="hover">
          <template #header><span>创作达人 Top10</span></template>
          <div class="rank-list">
            <div v-for="(item, i) in rankings.top_creators" :key="item.id" class="rank-item">
              <span class="rank-num" :class="{ 'top3': i < 3 }">{{ i + 1 }}</span>
              <span class="rank-title">{{ item.nickname }}</span>
              <span class="rank-count">{{ item.ai_count }}次AI创作</span>
            </div>
            <el-empty v-if="!rankings.top_creators?.length" description="暂无数据" :image-size="60" />
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart, PieChart } from 'echarts/charts'
import {
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent
} from 'echarts/components'
import VChart from 'vue-echarts'
import axios from 'axios'

use([
  CanvasRenderer,
  LineChart,
  PieChart,
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent
])

const loading = ref(false)
const trendDays = ref(7)
const stats = ref({})
const trend = ref({})
const distribution = ref({})
const rankings = ref({})

const totalCards = [
  { key: 'users', label: '总用户', color: '#409eff' },
  { key: 'songs', label: '总歌曲', color: '#67c23a' },
  { key: 'ai_tasks', label: '总AI创作', color: '#e6a23c' },
  { key: 'posts', label: '总动态', color: '#f56c6c' },
  { key: 'comments', label: '总评论', color: '#909399' },
  { key: 'likes', label: '总点赞', color: '#b37feb' }
]

const todayCards = [
  { key: 'new_users', label: '新增用户' },
  { key: 'new_songs', label: '新增歌曲' },
  { key: 'new_ai_tasks', label: '新增AI任务' },
  { key: 'new_posts', label: '新增动态' },
  { key: 'new_comments', label: '新增评论' },
  { key: 'new_likes', label: '新增点赞' }
]

const formatNum = (n) => {
  if (n == null) return '0'
  if (n >= 10000) return (n / 10000).toFixed(1) + '万'
  return n.toLocaleString()
}

const formatMoney = (n) => {
  if (n == null) return '0'
  return (n / 100).toFixed(2)
}

// 趋势图配置
const makeTrendOption = (dates, data, name, color) => ({
  tooltip: { trigger: 'axis' },
  grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
  xAxis: { type: 'category', data: dates, boundaryGap: false },
  yAxis: { type: 'value' },
  series: [{
    name,
    type: 'line',
    data,
    smooth: true,
    areaStyle: { opacity: 0.3 },
    itemStyle: { color }
  }]
})

const userTrendOption = computed(() =>
  makeTrendOption(trend.value.dates, trend.value.users, '新增用户', '#409eff')
)
const songTrendOption = computed(() =>
  makeTrendOption(trend.value.dates, trend.value.songs, '新增歌曲', '#67c23a')
)
const aiTrendOption = computed(() =>
  makeTrendOption(trend.value.dates, trend.value.ai_tasks, 'AI任务', '#e6a23c')
)
const postTrendOption = computed(() =>
  makeTrendOption(trend.value.dates, trend.value.posts, '新增动态', '#f56c6c')
)

// 饼图配置
const makePieOption = (data, name) => ({
  tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
  legend: { orient: 'vertical', left: 'left', top: 'middle' },
  series: [{
    name,
    type: 'pie',
    radius: ['40%', '70%'],
    center: ['60%', '50%'],
    avoidLabelOverlap: false,
    itemStyle: { borderRadius: 10, borderColor: '#fff', borderWidth: 2 },
    label: { show: false },
    emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold' } },
    labelLine: { show: false },
    data: data || []
  }]
})

const colors = ['#409eff', '#67c23a', '#e6a23c', '#f56c6c', '#909399', '#b37feb', '#36cfc9', '#ff85c0', '#ffc53d', '#73d13d']

const styleDistOption = computed(() => {
  const data = (distribution.value.song_styles || []).map((item, i) => ({
    ...item,
    itemStyle: { color: colors[i % colors.length] }
  }))
  return makePieOption(data, '风格分布')
})

const emotionDistOption = computed(() => {
  const data = (distribution.value.song_emotions || []).map((item, i) => ({
    ...item,
    itemStyle: { color: colors[i % colors.length] }
  }))
  return makePieOption(data, '情绪分布')
})

const memberDistOption = computed(() => {
  const data = (distribution.value.member_levels || []).map((item, i) => ({
    ...item,
    itemStyle: { color: colors[i % colors.length] }
  }))
  return makePieOption(data, '会员分布')
})

// 加载数据
const loadStats = async () => {
  try {
    const res = await axios.get('/api/admin/dashboard/stats')
    if (res.data.code === 200) {
      stats.value = res.data.data
    }
  } catch (e) {
    console.error('加载统计数据失败', e)
  }
}

const loadTrend = async () => {
  try {
    const res = await axios.get('/api/admin/dashboard/trend', { params: { days: trendDays.value } })
    if (res.data.code === 200) {
      trend.value = res.data.data
    }
  } catch (e) {
    console.error('加载趋势数据失败', e)
  }
}

const loadDistribution = async () => {
  try {
    const res = await axios.get('/api/admin/dashboard/distribution')
    if (res.data.code === 200) {
      distribution.value = res.data.data
    }
  } catch (e) {
    console.error('加载分布数据失败', e)
  }
}

const loadRankings = async () => {
  try {
    const res = await axios.get('/api/admin/dashboard/ranking')
    if (res.data.code === 200) {
      rankings.value = res.data.data
    }
  } catch (e) {
    console.error('加载排行榜失败', e)
  }
}

const loadAll = async () => {
  loading.value = true
  await Promise.all([loadStats(), loadTrend(), loadDistribution(), loadRankings()])
  loading.value = false
}

onMounted(() => {
  loadAll()
})
</script>

<style scoped>
.dashboard {
  padding: 0;
}

.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.dashboard-header h2 {
  margin: 0;
  font-size: 20px;
}

.time-filter {
  display: flex;
  align-items: center;
}

.kpi-row {
  margin-bottom: 16px;
}

.kpi-card {
  text-align: center;
  margin-bottom: 8px;
}

.kpi-card.today {
  border-top: 3px solid #67c23a;
}

.kpi-value {
  font-size: 28px;
  font-weight: bold;
  margin-bottom: 4px;
}

.today-value {
  color: #67c23a;
}

.kpi-label {
  font-size: 13px;
  color: #909399;
}

.section-row {
  margin-bottom: 16px;
}

.info-card .info-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.info-item {
  text-align: center;
}

.info-num {
  display: block;
  font-size: 20px;
  font-weight: bold;
  color: #303133;
}

.info-desc {
  font-size: 12px;
  color: #909399;
}

.chart {
  height: 300px;
}

.rank-list {
  max-height: 320px;
  overflow-y: auto;
}

.rank-item {
  display: flex;
  align-items: center;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.rank-item:last-child {
  border-bottom: none;
}

.rank-num {
  width: 24px;
  height: 24px;
  line-height: 24px;
  text-align: center;
  border-radius: 4px;
  background: #f0f0f0;
  color: #909399;
  font-size: 12px;
  margin-right: 12px;
  flex-shrink: 0;
}

.rank-num.top3 {
  background: linear-gradient(135deg, #ff85c0, #b37feb);
  color: #fff;
}

.rank-title {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 14px;
}

.rank-count {
  color: #909399;
  font-size: 12px;
  margin-left: 12px;
  flex-shrink: 0;
}
</style>

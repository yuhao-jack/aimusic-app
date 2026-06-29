
<template>
  <div>
    <h2 style="margin-bottom: 20px;">用户行为分析</h2>

    <!-- 顶部指标卡片 -->
    <el-row :gutter="20" style="margin-bottom: 24px;">
      <el-col :span="6" v-for="card in metricCards" :key="card.title">
        <el-card shadow="hover">
          <div class="metric-card">
            <div class="metric-card__title">{{ card.title }}</div>
            <div class="metric-card__value" :style="{ color: card.color }">{{ card.value }}</div>
            <div class="metric-card__trend" :class="card.trendDir === 'up' ? 'trend-up' : 'trend-down'">
              {{ card.trendDir === 'up' ? '↑' : '↓' }} {{ card.trend }}
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 用户活跃度趋势图 -->
    <el-card style="margin-bottom: 24px;">
      <template #header>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span>用户活跃度趋势</span>
          <el-radio-group v-model="activeMetric" size="small">
            <el-radio-button value="dau">日活</el-radio-button>
            <el-radio-button value="wau">周活</el-radio-button>
            <el-radio-button value="mau">月活</el-radio-button>
          </el-radio-group>
        </div>
      </template>
      <div class="chart-container">
        <div class="bar-chart">
          <div v-for="(item, index) in activeTrend" :key="index" class="bar-chart__item">
            <div class="bar-chart__bar-wrapper">
              <div
                class="bar-chart__bar"
                :style="{ height: getBarHeight(item.value) + '%', backgroundColor: activeColor }"
              >
                <span class="bar-chart__tooltip">{{ item.label }}: {{ item.value }}</span>
              </div>
            </div>
            <div class="bar-chart__label">{{ item.date }}</div>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 用户留存率 -->
    <el-card style="margin-bottom: 24px;">
      <template #header>用户留存率</template>
      <el-row :gutter="20">
        <el-col :span="8" v-for="item in retentionData" :key="item.period">
          <div class="retention-card">
            <div class="retention-card__period">{{ item.period }}</div>
            <div class="retention-card__rate" :style="{ color: getRetentionColor(item.rate) }">
              {{ item.rate }}%
            </div>
            <div class="retention-card__bar-bg">
              <div class="retention-card__bar" :style="{ width: item.rate + '%', backgroundColor: getRetentionColor(item.rate) }"></div>
            </div>
            <div class="retention-card__desc">{{ item.desc }}</div>
          </div>
        </el-col>
      </el-row>
    </el-card>

    <!-- 用户行为漏斗 -->
    <el-card style="margin-bottom: 24px;">
      <template #header>用户行为漏斗</template>
      <div class="funnel-container">
        <div v-for="(item, index) in funnelData" :key="index" class="funnel-step">
          <div class="funnel-bar" :style="{ width: item.rate + '%', backgroundColor: funnelColors[index] }">
            <span class="funnel-label">{{ item.name }}</span>
            <span class="funnel-value">{{ item.count }}人</span>
            <span class="funnel-rate">{{ item.rate }}%</span>
          </div>
          <div v-if="index < funnelData.length - 1" class="funnel-arrow">
            ↓ 转化率 {{ item.conversionRate }}%
          </div>
        </div>
      </div>
    </el-card>

    <!-- 热门功能使用排行 -->
    <el-card>
      <template #header>热门功能使用排行</template>
      <el-table :data="featureRank" border>
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column type="index" label="排名" width="80" />
        <el-table-column prop="name" label="功能名称" width="180" />
        <el-table-column prop="usage_count" label="使用次数" width="150">
          <template #default="{ row }">
            {{ row.usage_count.toLocaleString() }}
          </template>
        </el-table-column>
        <el-table-column label="使用占比" width="200">
          <template #default="{ row }">
            <el-progress :percentage="row.percent" :color="row.color" />
          </template>
        </el-table-column>
        <el-table-column prop="trend" label="趋势" width="120">
          <template #default="{ row }">
            <span :class="row.trendDir === 'up' ? 'trend-up' : 'trend-down'">
              {{ row.trendDir === 'up' ? '↑' : '↓' }} {{ row.trend }}
            </span>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import axios from 'axios'

// 顶部指标卡片
const metricCards = ref([
  { title: '今日活跃用户', value: '12,456', color: '#409eff', trend: '8.5%', trendDir: 'up' },
  { title: '今日新增用户', value: '856', color: '#67c23a', trend: '12.3%', trendDir: 'up' },
  { title: '次日留存率', value: '68.5%', color: '#e6a23c', trend: '2.1%', trendDir: 'down' },
  { title: '人均使用时长', value: '23.5分钟', color: '#f56c6c', trend: '5.2%', trendDir: 'up' }
])

// 活跃度趋势
const activeMetric = ref('dau')
const activeColor = computed(() => {
  const colors = { dau: '#409eff', wau: '#67c23a', mau: '#e6a23c' }
  return colors[activeMetric.value]
})

// 模拟活跃度趋势数据
const activeTrend = computed(() => {
  const days = 14
  const data = []
  for (let i = days - 1; i >= 0; i--) {
    const date = new Date()
    date.setDate(date.getDate() - i)
    const dateStr = `${date.getMonth() + 1}/${date.getDate()}`
    let value
    if (activeMetric.value === 'dau') {
      value = Math.floor(10000 + Math.random() * 5000)
    } else if (activeMetric.value === 'wau') {
      value = Math.floor(35000 + Math.random() * 15000)
    } else {
      value = Math.floor(120000 + Math.random() * 50000)
    }
    data.push({ date: dateStr, label: dateStr, value })
  }
  return data
})

const getBarHeight = (value) => {
  const data = activeTrend.value
  if (!data.length) return 0
  const max = Math.max(...data.map(d => d.value), 1)
  return (value / max) * 100
}

// 留存数据
const retentionData = ref([
  { period: '次日留存', rate: 68.5, desc: '新用户次日回访比例' },
  { period: '7日留存', rate: 42.3, desc: '新用户7日内回访比例' },
  { period: '30日留存', rate: 28.7, desc: '新用户30日内回访比例' }
])

const getRetentionColor = (rate) => {
  if (rate >= 60) return '#67c23a'
  if (rate >= 40) return '#e6a23c'
  return '#f56c6c'
}

// 漏斗数据
const funnelData = ref([
  { name: '注册用户', count: 10000, rate: 100, conversionRate: 45.2 },
  { name: '首次创作', count: 4520, rate: 45.2, conversionRate: 62.5 },
  { name: '首次分享', count: 2825, rate: 28.3, conversionRate: 35.8 },
  { name: '付费用户', count: 1011, rate: 10.1, conversionRate: null }
])

const funnelColors = ['#409eff', '#67c23a', '#e6a23c', '#f56c6c']

// 热门功能排行
const featureRank = ref([
  { name: 'AI作词', usage_count: 45678, percent: 85, color: '#409eff', trend: '12%', trendDir: 'up' },
  { name: 'AI作曲', usage_count: 38921, percent: 72, color: '#67c23a', trend: '8%', trendDir: 'up' },
  { name: '一起听', usage_count: 28456, percent: 53, color: '#e6a23c', trend: '15%', trendDir: 'up' },
  { name: '歌单创建', usage_count: 21345, percent: 40, color: '#f56c6c', trend: '3%', trendDir: 'down' },
  { name: '动态发布', usage_count: 18234, percent: 34, color: '#909399', trend: '5%', trendDir: 'up' },
  { name: '音色克隆', usage_count: 12456, percent: 23, color: '#c0c4cc', trend: '20%', trendDir: 'up' }
])

// 加载用户行为数据
const loadUserBehavior = async () => {
  try {
    const res = await axios.get('/api/admin/analytics/user-behavior')
    if (res.data.code === 200) {
      const data = res.data.data
      if (data.metric_cards) {
        metricCards.value = data.metric_cards
      }
      if (data.feature_rank) {
        featureRank.value = data.feature_rank
      }
    }
  } catch (err) {
    console.error('加载用户行为数据失败', err)
  }
}

// 加载留存数据
const loadRetention = async () => {
  try {
    const res = await axios.get('/api/admin/analytics/retention')
    if (res.data.code === 200) {
      retentionData.value = res.data.data
    }
  } catch (err) {
    console.error('加载留存数据失败', err)
  }
}

// 加载漏斗数据
const loadFunnel = async () => {
  try {
    const res = await axios.get('/api/admin/analytics/funnel')
    if (res.data.code === 200) {
      funnelData.value = res.data.data
    }
  } catch (err) {
    console.error('加载漏斗数据失败', err)
  }
}

onMounted(() => {
  loadUserBehavior()
  loadRetention()
  loadFunnel()
})
</script>

<style scoped>
.metric-card {
  text-align: center;
  padding: 10px 0;
}
.metric-card__title {
  font-size: 14px;
  color: #909399;
  margin-bottom: 10px;
}
.metric-card__value {
  font-size: 28px;
  font-weight: bold;
}
.metric-card__trend {
  font-size: 13px;
  margin-top: 6px;
}

.trend-up {
  color: #67c23a;
}
.trend-down {
  color: #f56c6c;
}

/* 柱状图 */
.chart-container {
  height: 300px;
  padding: 20px 0;
}
.bar-chart {
  display: flex;
  align-items: flex-end;
  height: 100%;
  gap: 2px;
}
.bar-chart__item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  height: 100%;
}
.bar-chart__bar-wrapper {
  flex: 1;
  width: 100%;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}
.bar-chart__bar {
  width: 70%;
  min-width: 6px;
  max-width: 24px;
  border-radius: 3px 3px 0 0;
  position: relative;
  transition: height 0.3s;
  cursor: pointer;
}
.bar-chart__bar:hover .bar-chart__tooltip {
  display: block;
}
.bar-chart__tooltip {
  display: none;
  position: absolute;
  top: -28px;
  left: 50%;
  transform: translateX(-50%);
  background: #303133;
  color: #fff;
  font-size: 12px;
  padding: 2px 6px;
  border-radius: 4px;
  white-space: nowrap;
}
.bar-chart__label {
  font-size: 11px;
  color: #909399;
  margin-top: 6px;
  transform: rotate(-45deg);
  white-space: nowrap;
}

/* 留存卡片 */
.retention-card {
  text-align: center;
  padding: 20px;
  border: 1px solid #ebeef5;
  border-radius: 8px;
  margin-bottom: 12px;
}
.retention-card__period {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  margin-bottom: 12px;
}
.retention-card__rate {
  font-size: 36px;
  font-weight: bold;
  margin-bottom: 12px;
}
.retention-card__bar-bg {
  height: 8px;
  background: #ebeef5;
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 8px;
}
.retention-card__bar {
  height: 100%;
  border-radius: 4px;
  transition: width 0.6s;
}
.retention-card__desc {
  font-size: 12px;
  color: #909399;
}

/* 漏斗图 */
.funnel-container {
  padding: 20px 0;
}
.funnel-step {
  text-align: center;
  margin-bottom: 8px;
}
.funnel-bar {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  height: 48px;
  border-radius: 6px;
  color: #fff;
  font-size: 14px;
  min-width: 300px;
  transition: width 0.5s;
}
.funnel-label {
  font-weight: 600;
}
.funnel-value {
  opacity: 0.9;
}
.funnel-rate {
  opacity: 0.8;
  font-size: 12px;
}
.funnel-arrow {
  color: #909399;
  font-size: 13px;
  margin: 4px 0;
}
</style>

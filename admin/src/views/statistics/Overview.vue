
<template>
  <div>
    <h2 style="margin-bottom: 20px;">数据总览</h2>

    <!-- 顶部数字卡片 -->
    <el-row :gutter="20" style="margin-bottom: 24px;">
      <el-col :span="6" v-for="card in statCards" :key="card.title">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-card__title">{{ card.title }}</div>
            <div class="stat-card__value">{{ card.value }}</div>
            <div class="stat-card__suffix">{{ card.suffix }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 趋势图区域 -->
    <el-card style="margin-bottom: 24px;">
      <template #header>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span>最近30天趋势</span>
          <el-radio-group v-model="trendType" size="small">
            <el-radio-button value="users">新增用户</el-radio-button>
            <el-radio-button value="plays">播放量</el-radio-button>
            <el-radio-button value="income">收入</el-radio-button>
          </el-radio-group>
        </div>
      </template>
      <div class="chart-container">
        <div class="bar-chart">
          <div
            v-for="(item, index) in currentTrendData"
            :key="index"
            class="bar-chart__item"
          >
            <div class="bar-chart__bar-wrapper">
              <div
                class="bar-chart__bar"
                :style="{ height: getBarHeight(item.value) + '%', backgroundColor: trendColor }"
              >
                <span class="bar-chart__tooltip">{{ item.value }}</span>
              </div>
            </div>
            <div class="bar-chart__label">{{ item.label }}</div>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 底部分布图 -->
    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <template #header>会员等级分布</template>
          <div class="distribution-list">
            <div v-for="item in memberDistribution" :key="item.name" class="distribution-item">
              <div class="distribution-item__info">
                <span>{{ item.name }}</span>
                <span>{{ item.count }} 人 ({{ item.percent }}%)</span>
              </div>
              <el-progress
                :percentage="item.percent"
                :color="item.color"
                :show-text="false"
              />
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header>歌曲风格分布</template>
          <div class="distribution-list">
            <div v-for="item in genreDistribution" :key="item.name" class="distribution-item">
              <div class="distribution-item__info">
                <span>{{ item.name }}</span>
                <span>{{ item.count }} 首 ({{ item.percent }}%)</span>
              </div>
              <el-progress
                :percentage="item.percent"
                :color="item.color"
                :show-text="false"
              />
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 行为漏斗 & 留存分析 -->
    <el-row :gutter="20" style="margin-top: 24px;">
      <el-col :span="12">
        <el-card>
          <template #header>行为漏斗（注册→首次创作→付费转化）</template>
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
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header>留存分析</template>
          <div class="retention-list">
            <div v-for="item in retentionData" :key="item.period" class="retention-item">
              <div class="retention-item__info">
                <span class="retention-item__period">{{ item.period }}</span>
                <span class="retention-item__rate" :style="{ color: getRetentionColor(item.rate) }">{{ item.rate }}%</span>
              </div>
              <div class="retention-item__bar-bg">
                <div class="retention-item__bar" :style="{ width: item.rate + '%', backgroundColor: getRetentionColor(item.rate) }"></div>
              </div>
              <div class="retention-item__desc">{{ item.desc }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

// 顶部统计卡片
const statCards = ref([
  { title: '今日新增用户', value: 0, suffix: '人' },
  { title: '今日活跃用户', value: 0, suffix: '人' },
  { title: '今日收入', value: 0, suffix: '元' },
  { title: '今日AI生成', value: 0, suffix: '首' }
])

// 趋势图类型
const trendType = ref('users')
// 趋势数据
const trendData = ref({
  users: [],
  plays: [],
  income: []
})

// 趋势图颜色
const trendColor = computed(() => {
  const colors = { users: '#409eff', plays: '#67c23a', income: '#e6a23c' }
  return colors[trendType.value]
})

// 当前趋势数据
const currentTrendData = computed(() => trendData.value[trendType.value] || [])

// 计算柱状图高度百分比
const getBarHeight = (value) => {
  const data = currentTrendData.value
  if (!data.length) return 0
  const max = Math.max(...data.map(d => d.value), 1)
  return (value / max) * 100
}

// 会员等级分布
const memberDistribution = ref([])
// 歌曲风格分布
const genreDistribution = ref([])

// 行为漏斗数据
const funnelData = ref([
  { name: '注册用户', count: 0, rate: 100, conversionRate: 0 },
  { name: '首次创作', count: 0, rate: 0, conversionRate: 0 },
  { name: '付费用户', count: 0, rate: 0, conversionRate: null }
])
const funnelColors = ['#409eff', '#67c23a', '#e6a23c']

// 留存数据
const retentionData = ref([
  { period: '次日留存', rate: 0, desc: '新用户次日回访比例' },
  { period: '7日留存', rate: 0, desc: '新用户7日内回访比例' },
  { period: '30日留存', rate: 0, desc: '新用户30日内回访比例' }
])

const getRetentionColor = (rate) => {
  if (rate >= 60) return '#67c23a'
  if (rate >= 40) return '#e6a23c'
  return '#f56c6c'
}

// 加载概览数据
const loadOverview = async () => {
  try {
    const res = await axios.get('/api/admin/dashboard/overview')
    if (res.data.code === 200) {
      const data = res.data.data
      statCards.value[0].value = data.today_new_users || 0
      statCards.value[1].value = data.today_active_users || 0
      statCards.value[2].value = data.today_income || 0
      statCards.value[3].value = data.today_ai_generated || 0
    }
  } catch (err) {
    console.error(err)
  }
}

// 加载趋势数据
const loadTrends = async () => {
  try {
    const res = await axios.get('/api/admin/dashboard/trend')
    if (res.data.code === 200) {
      trendData.value = res.data.data
    }
  } catch (err) {
    console.error(err)
    trendData.value = { users: [], plays: [], income: [] }
  }
}

// 加载分布数据
const loadDistribution = async () => {
  try {
    const res = await axios.get('/api/admin/dashboard/distribution')
    if (res.data.code === 200) {
      memberDistribution.value = res.data.data.members || []
      genreDistribution.value = res.data.data.genres || []
    }
  } catch (err) {
    console.error(err)
    memberDistribution.value = []
    genreDistribution.value = []
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

onMounted(() => {
  loadOverview()
  loadTrends()
  loadDistribution()
  loadFunnel()
  loadRetention()
})
</script>

<style scoped>
.stat-card {
  text-align: center;
  padding: 10px 0;
}
.stat-card__title {
  font-size: 14px;
  color: #909399;
  margin-bottom: 10px;
}
.stat-card__value {
  font-size: 32px;
  font-weight: bold;
  color: #303133;
}
.stat-card__suffix {
  font-size: 14px;
  color: #909399;
  margin-top: 4px;
}

/* 柱状图样式 */
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

/* 分布列表样式 */
.distribution-list {
  padding: 10px 0;
}
.distribution-item {
  margin-bottom: 16px;
}
.distribution-item:last-child {
  margin-bottom: 0;
}
.distribution-item__info {
  display: flex;
  justify-content: space-between;
  margin-bottom: 6px;
  font-size: 14px;
  color: #606266;
}

/* 漏斗图样式 */
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
  height: 44px;
  border-radius: 6px;
  color: #fff;
  font-size: 14px;
  min-width: 260px;
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

/* 留存分析样式 */
.retention-list {
  padding: 10px 0;
}
.retention-item {
  margin-bottom: 24px;
}
.retention-item:last-child {
  margin-bottom: 0;
}
.retention-item__info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}
.retention-item__period {
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}
.retention-item__rate {
  font-size: 28px;
  font-weight: bold;
}
.retention-item__bar-bg {
  height: 10px;
  background: #ebeef5;
  border-radius: 5px;
  overflow: hidden;
  margin-bottom: 6px;
}
.retention-item__bar {
  height: 100%;
  border-radius: 5px;
  transition: width 0.6s;
}
.retention-item__desc {
  font-size: 12px;
  color: #909399;
}
</style>

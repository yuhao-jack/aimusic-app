
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

onMounted(() => {
  loadOverview()
  loadTrends()
  loadDistribution()
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
</style>

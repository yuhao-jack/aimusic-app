
<template>
  <div>
    <h2 style="margin-bottom: 20px;">营收分析</h2>

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

    <!-- 营收趋势图 -->
    <el-card style="margin-bottom: 24px;">
      <template #header>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span>营收趋势</span>
          <el-radio-group v-model="revenuePeriod" size="small">
            <el-radio-button value="day">日</el-radio-button>
            <el-radio-button value="week">周</el-radio-button>
            <el-radio-button value="month">月</el-radio-button>
          </el-radio-group>
        </div>
      </template>
      <div class="chart-container">
        <div class="bar-chart">
          <div v-for="(item, index) in revenueTrend" :key="index" class="bar-chart__item">
            <div class="bar-chart__bar-wrapper">
              <div
                class="bar-chart__bar"
                :style="{ height: getBarHeight(item.value) + '%', backgroundColor: '#e6a23c' }"
              >
                <span class="bar-chart__tooltip">{{ item.label }}: ¥{{ item.value.toLocaleString() }}</span>
              </div>
            </div>
            <div class="bar-chart__label">{{ item.label }}</div>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 营收来源分布 + 用户付费率 -->
    <el-row :gutter="20" style="margin-bottom: 24px;">
      <el-col :span="12">
        <el-card>
          <template #header>营收来源分布</template>
          <div class="source-list">
            <div v-for="item in revenueSources" :key="item.name" class="source-item">
              <div class="source-item__header">
                <span class="source-item__name">
                  <span class="source-item__dot" :style="{ backgroundColor: item.color }"></span>
                  {{ item.name }}
                </span>
                <span class="source-item__amount">¥{{ item.amount.toLocaleString() }}</span>
              </div>
              <el-progress :percentage="item.percent" :color="item.color" :show-text="false" />
              <div class="source-item__percent">{{ item.percent }}%</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header>用户付费分析</template>
          <div class="payment-stats">
            <div class="payment-stat">
              <div class="payment-stat__label">总用户数</div>
              <div class="payment-stat__value">23,456</div>
            </div>
            <div class="payment-stat">
              <div class="payment-stat__label">付费用户数</div>
              <div class="payment-stat__value highlight">3,456</div>
            </div>
            <div class="payment-stat">
              <div class="payment-stat__label">付费率</div>
              <div class="payment-stat__value primary">14.7%</div>
            </div>
            <div class="payment-stat">
              <div class="payment-stat__label">ARPU值</div>
              <div class="payment-stat__value warning">¥8.56</div>
            </div>
          </div>
          <div style="margin-top: 20px;">
            <div class="arpu-bar">
              <div class="arpu-bar__label">VIP用户ARPU</div>
              <div class="arpu-bar__track">
                <div class="arpu-bar__fill" style="width: 85%; background: #409eff;">¥45.2</div>
              </div>
            </div>
            <div class="arpu-bar">
              <div class="arpu-bar__label">普通用户ARPU</div>
              <div class="arpu-bar__track">
                <div class="arpu-bar__fill" style="width: 25%; background: #67c23a;">¥3.8</div>
              </div>
            </div>
            <div class="arpu-bar">
              <div class="arpu-bar__label">新用户ARPU</div>
              <div class="arpu-bar__track">
                <div class="arpu-bar__fill" style="width: 10%; background: #e6a23c;">¥1.2</div>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 热门套餐排行 -->
    <el-card>
      <template #header>热门套餐排行</template>
      <el-table :data="packageRank" border>
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column type="index" label="排名" width="80" />
        <el-table-column prop="name" label="套餐名称" min-width="180" />
        <el-table-column prop="type" label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="row.type === 'vip' ? '' : 'warning'">
              {{ row.type === 'vip' ? 'VIP订阅' : '音币充值' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="price" label="价格" width="120">
          <template #default="{ row }">
            ¥{{ row.price }}
          </template>
        </el-table-column>
        <el-table-column prop="sales" label="销量" width="120">
          <template #default="{ row }">
            {{ row.sales.toLocaleString() }}
          </template>
        </el-table-column>
        <el-table-column prop="revenue" label="营收" width="150">
          <template #default="{ row }">
            ¥{{ row.revenue.toLocaleString() }}
          </template>
        </el-table-column>
        <el-table-column label="占比" width="150">
          <template #default="{ row }">
            <el-progress :percentage="row.percent" :color="row.color" />
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
  { title: '今日营收', value: '¥12,456', color: '#e6a23c', trend: '15.2%', trendDir: 'up' },
  { title: '本月营收', value: '¥356,789', color: '#409eff', trend: '8.7%', trendDir: 'up' },
  { title: '付费率', value: '14.7%', color: '#67c23a', trend: '2.1%', trendDir: 'up' },
  { title: 'ARPU值', value: '¥8.56', color: '#f56c6c', trend: '1.5%', trendDir: 'down' }
])

// 营收趋势周期
const revenuePeriod = ref('day')

// 模拟营收趋势数据
const revenueTrend = computed(() => {
  const data = []
  let days
  if (revenuePeriod.value === 'day') {
    days = 14
    for (let i = days - 1; i >= 0; i--) {
      const date = new Date()
      date.setDate(date.getDate() - i)
      data.push({
        label: `${date.getMonth() + 1}/${date.getDate()}`,
        value: Math.floor(8000 + Math.random() * 8000)
      })
    }
  } else if (revenuePeriod.value === 'week') {
    for (let i = 7; i >= 0; i--) {
      const date = new Date()
      date.setDate(date.getDate() - i * 7)
      data.push({
        label: `第${8 - i}周`,
        value: Math.floor(50000 + Math.random() * 30000)
      })
    }
  } else {
    for (let i = 5; i >= 0; i--) {
      const date = new Date()
      date.setMonth(date.getMonth() - i)
      data.push({
        label: `${date.getMonth() + 1}月`,
        value: Math.floor(200000 + Math.random() * 150000)
      })
    }
  }
  return data
})

const getBarHeight = (value) => {
  const data = revenueTrend.value
  if (!data.length) return 0
  const max = Math.max(...data.map(d => d.value), 1)
  return (value / max) * 100
}

// 营收来源分布（模拟数据）
const revenueSources = ref([
  { name: 'VIP订阅', amount: 123456, percent: 45, color: '#409eff' },
  { name: '音币充值', amount: 87654, percent: 32, color: '#67c23a' },
  { name: '单曲购买', amount: 34567, percent: 13, color: '#e6a23c' },
  { name: '其他', amount: 27223, percent: 10, color: '#909399' }
])

// 热门套餐排行（模拟数据）
const packageRank = ref([
  { name: 'VIP月度订阅', type: 'vip', price: 28, sales: 12345, revenue: 345660, percent: 28, color: '#409eff' },
  { name: 'VIP年度订阅', type: 'vip', price: 268, sales: 5678, revenue: 1521704, percent: 35, color: '#67c23a' },
  { name: '100音币充值包', type: 'coin', price: 10, sales: 23456, revenue: 234560, percent: 18, color: '#e6a23c' },
  { name: '500音币充值包', type: 'coin', price: 45, sales: 8901, revenue: 400545, percent: 12, color: '#f56c6c' },
  { name: 'VIP季度订阅', type: 'vip', price: 78, sales: 3456, revenue: 269568, percent: 7, color: '#909399' }
])

// 加载营收数据
const loadRevenue = async () => {
  try {
    const res = await axios.get('/api/admin/analytics/revenue')
    if (res.data.code === 200) {
      const data = res.data.data
      if (data.metric_cards) {
        metricCards.value = data.metric_cards
      }
      if (data.revenue_sources) {
        revenueSources.value = data.revenue_sources
      }
      if (data.package_rank) {
        packageRank.value = data.package_rank
      }
    }
  } catch (err) {
    console.error('加载营收数据失败', err)
  }
}

onMounted(() => {
  loadRevenue()
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
  gap: 4px;
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
  min-width: 12px;
  max-width: 36px;
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
  font-size: 12px;
  color: #909399;
  margin-top: 8px;
}

/* 营收来源 */
.source-list {
  padding: 10px 0;
}
.source-item {
  margin-bottom: 20px;
}
.source-item:last-child {
  margin-bottom: 0;
}
.source-item__header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
}
.source-item__name {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  color: #303133;
}
.source-item__dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}
.source-item__amount {
  font-size: 14px;
  font-weight: 600;
  color: #303133;
}
.source-item__percent {
  text-align: right;
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
}

/* 付费统计 */
.payment-stats {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}
.payment-stat {
  text-align: center;
  padding: 16px;
  border: 1px solid #ebeef5;
  border-radius: 8px;
}
.payment-stat__label {
  font-size: 13px;
  color: #909399;
  margin-bottom: 8px;
}
.payment-stat__value {
  font-size: 24px;
  font-weight: bold;
  color: #303133;
}
.payment-stat__value.highlight {
  color: #409eff;
}
.payment-stat__value.primary {
  color: #67c23a;
}
.payment-stat__value.warning {
  color: #e6a23c;
}

/* ARPU条形图 */
.arpu-bar {
  margin-bottom: 12px;
}
.arpu-bar__label {
  font-size: 13px;
  color: #606266;
  margin-bottom: 6px;
}
.arpu-bar__track {
  height: 24px;
  background: #ebeef5;
  border-radius: 4px;
  overflow: hidden;
}
.arpu-bar__fill {
  height: 100%;
  border-radius: 4px;
  color: #fff;
  font-size: 12px;
  display: flex;
  align-items: center;
  padding-left: 8px;
  transition: width 0.5s;
}
</style>

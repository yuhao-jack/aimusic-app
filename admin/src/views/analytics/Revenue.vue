<template>
  <div>
    <h2 style="margin-bottom: 20px;">营收分析</h2>

    <!-- 核心指标 -->
    <el-row :gutter="16" style="margin-bottom: 20px;">
      <el-col :span="6">
        <el-card shadow="hover" class="metric-card">
          <div class="metric-value gold">¥{{ formatMoney(revenue.today_revenue) }}</div>
          <div class="metric-label">今日营收</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="metric-card">
          <div class="metric-value primary">¥{{ formatMoney(revenue.month_revenue) }}</div>
          <div class="metric-label">本月营收</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="metric-card">
          <div class="metric-value success">{{ revenue.paid_users || 0 }}</div>
          <div class="metric-label">付费用户</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="metric-card">
          <div class="metric-value info">{{ revenue.pay_rate || '0' }}%</div>
          <div class="metric-label">付费率</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 营收趋势 -->
    <el-card style="margin-bottom: 20px;">
      <template #header><span>7天营收趋势</span></template>
      <v-chart class="trend-chart" :option="trendOption" autoresize />
    </el-card>

    <!-- 收入来源 + 财务报表 -->
    <el-row :gutter="16">
      <el-col :span="12">
        <el-card>
          <template #header><span>收入来源</span></template>
          <el-table :data="revenue.sources || []" border>
            <el-table-column prop="name" label="来源" />
            <el-table-column label="金额">
              <template #default="{ row }">¥{{ formatMoney(row.amount) }}</template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header>
            <div style="display: flex; justify-content: space-between; align-items: center;">
              <span>财务报表</span>
              <el-button type="primary" size="small" @click="exportCSV">导出CSV</el-button>
            </div>
          </template>
          <el-radio-group v-model="reportType" size="small" @change="loadReport" style="margin-bottom: 16px;">
            <el-radio-button value="daily">日报</el-radio-button>
            <el-radio-button value="weekly">周报</el-radio-button>
            <el-radio-button value="monthly">月报</el-radio-button>
          </el-radio-group>
          <el-table :data="report.reports || []" border size="small">
            <el-table-column prop="date" label="日期" width="120" />
            <el-table-column prop="order_count" label="订单数" width="80" />
            <el-table-column label="收入">
              <template #default="{ row }">¥{{ formatMoney(row.revenue) }}</template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart } from 'echarts/charts'
import { TitleComponent, TooltipComponent, GridComponent } from 'echarts/components'
import VChart from 'vue-echarts'
import axios from 'axios'

use([CanvasRenderer, LineChart, TitleComponent, TooltipComponent, GridComponent])

const revenue = ref({})
const reportType = ref('daily')
const report = ref({})

const formatMoney = (n) => n == null ? '0.00' : (n / 100).toFixed(2)

const trendOption = computed(() => {
  const trend = revenue.value.trend || {}
  return {
    tooltip: { trigger: 'axis', formatter: (p) => `${p[0].name}<br/>${p[0].seriesName}: ¥${(p[0].value / 100).toFixed(2)}` },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: trend.dates || [] },
    yAxis: { type: 'value', axisLabel: { formatter: (v) => '¥' + (v / 100).toFixed(0) } },
    series: [{
      name: '营收',
      type: 'line',
      data: trend.revenue || [],
      smooth: true,
      areaStyle: { opacity: 0.3 },
      itemStyle: { color: '#e6a23c' }
    }]
  }
})

const loadRevenue = async () => {
  try {
    const res = await axios.get('/api/admin/analytics/real-revenue')
    if (res.data.code === 200) revenue.value = res.data.data
  } catch (e) { console.error(e) }
}

const loadReport = async () => {
  try {
    const res = await axios.get('/api/admin/finance/report', { params: { type: reportType.value } })
    if (res.data.code === 200) report.value = res.data.data
  } catch (e) { console.error(e) }
}

const exportCSV = () => {
  const token = localStorage.getItem('admin_token')
  window.open(`/api/admin/finance/export?token=${token}`)
}

onMounted(() => {
  loadRevenue()
  loadReport()
})
</script>

<style scoped>
.metric-card { text-align: center; }
.metric-value { font-size: 28px; font-weight: bold; margin-bottom: 4px; }
.metric-value.gold { color: #e6a23c; }
.metric-value.primary { color: #409eff; }
.metric-value.success { color: #67c23a; }
.metric-value.info { color: #909399; }
.metric-label { font-size: 13px; color: #909399; }
.trend-chart { height: 300px; }
</style>

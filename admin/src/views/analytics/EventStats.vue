<template>
  <div>
    <h2 style="margin-bottom: 20px;">用户行为分析</h2>

    <!-- DAU/WAU/MAU -->
    <el-row :gutter="16" style="margin-bottom: 20px;">
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-value primary">{{ dauStats.dau || 0 }}</div>
          <div class="stat-label">DAU (日活)</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-value success">{{ dauStats.wau || 0 }}</div>
          <div class="stat-label">WAU (周活)</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-value warning">{{ dauStats.mau || 0 }}</div>
          <div class="stat-label">MAU (月活)</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-value">{{ dauStats.dau_rate || '0' }}%</div>
          <div class="stat-label">DAU/总用户</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- DAU趋势 -->
    <el-card style="margin-bottom: 20px;">
      <template #header><span>7天DAU趋势</span></template>
      <v-chart class="chart" :option="dauTrendOption" autoresize />
    </el-card>

    <!-- 事件统计 -->
    <el-card>
      <template #header><span>事件统计 (近7天)</span></template>
      <el-table :data="eventStats" border>
        <template #empty><el-empty description="暂无数据" /></template>
        <el-table-column type="index" label="#" width="60" />
        <el-table-column prop="event_name" label="事件名称" />
        <el-table-column prop="count" label="触发次数" width="120" sortable />
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart, BarChart } from 'echarts/charts'
import { TitleComponent, TooltipComponent, GridComponent } from 'echarts/components'
import VChart from 'vue-echarts'
import axios from 'axios'

use([CanvasRenderer, LineChart, BarChart, TitleComponent, TooltipComponent, GridComponent])

const dauStats = ref({})
const eventStats = ref([])

const dauTrendOption = computed(() => {
  const trend = dauStats.value.dau_trend || []
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: ['6天前', '5天前', '4天前', '3天前', '2天前', '昨天', '今天'] },
    yAxis: { type: 'value' },
    series: [{ type: 'line', data: trend, smooth: true, areaStyle: { opacity: 0.3 }, itemStyle: { color: '#409eff' } }]
  }
})

const loadData = async () => {
  try {
    const [dauRes, eventRes] = await Promise.all([
      axios.get('/api/admin/analytics/dau'),
      axios.get('/api/admin/events/stats')
    ])
    if (dauRes.data.code === 200) dauStats.value = dauRes.data.data
    if (eventRes.data.code === 200) eventStats.value = eventRes.data.data.event_stats || []
  } catch (e) { console.error(e) }
}

onMounted(() => loadData())
</script>

<style scoped>
.stat-card { text-align: center; }
.stat-value { font-size: 28px; font-weight: bold; margin-bottom: 4px; }
.stat-value.primary { color: #409eff; }
.stat-value.success { color: #67c23a; }
.stat-value.warning { color: #e6a23c; }
.stat-label { font-size: 13px; color: #909399; }
.chart { height: 300px; }
</style>

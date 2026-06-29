<template>
  <div>
    <h2 style="margin-bottom: 20px;">实时监控</h2>
    <el-button type="primary" size="small" @click="loadAll" :loading="loading" style="margin-bottom: 16px;">
      <el-icon><Refresh /></el-icon> 刷新数据
    </el-button>

    <!-- 实时指标 -->
    <el-row :gutter="16" style="margin-bottom: 20px;">
      <el-col :span="4">
        <el-card shadow="hover" class="monitor-card live">
          <div class="monitor-value">{{ realtime.today_active_users || 0 }}</div>
          <div class="monitor-label">今日活跃用户</div>
        </el-card>
      </el-col>
      <el-col :span="4">
        <el-card shadow="hover" class="monitor-card">
          <div class="monitor-value primary">{{ realtime.today_plays || 0 }}</div>
          <div class="monitor-label">今日播放量</div>
        </el-card>
      </el-col>
      <el-col :span="4">
        <el-card shadow="hover" class="monitor-card">
          <div class="monitor-value success">{{ realtime.hour_plays || 0 }}</div>
          <div class="monitor-label">近1小时播放</div>
        </el-card>
      </el-col>
      <el-col :span="4">
        <el-card shadow="hover" class="monitor-card">
          <div class="monitor-value warning">{{ realtime.waiting_tasks || 0 }}</div>
          <div class="monitor-label">AI等待队列</div>
        </el-card>
      </el-col>
      <el-col :span="4">
        <el-card shadow="hover" class="monitor-card">
          <div class="monitor-value info">{{ realtime.running_tasks || 0 }}</div>
          <div class="monitor-label">AI处理中</div>
        </el-card>
      </el-col>
      <el-col :span="4">
        <el-card shadow="hover" class="monitor-card">
          <div class="monitor-value">{{ totals.users || 0 }}</div>
          <div class="monitor-label">总用户数</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 今日数据 -->
    <el-row :gutter="16" style="margin-bottom: 20px;">
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="today-item">
            <span class="today-num">{{ today.new_users || 0 }}</span>
            <span class="today-desc">今日新增用户</span>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="today-item">
            <span class="today-num">{{ today.new_songs || 0 }}</span>
            <span class="today-desc">今日新增歌曲</span>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="today-item">
            <span class="today-num">{{ today.new_posts || 0 }}</span>
            <span class="today-desc">今日新增动态</span>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="today-item">
            <span class="today-num">{{ today.ai_tasks || 0 }}</span>
            <span class="today-desc">今日AI任务</span>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- API调用统计 -->
    <el-row :gutter="16">
      <el-col :span="12">
        <el-card>
          <template #header><span>今日API调用量: {{ apiStats.today_total || 0 }}</span></template>
          <v-chart class="chart" :option="hourlyOption" autoresize />
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header><span>API调用分布 Top10</span></template>
          <el-table :data="apiStats.by_action || []" border size="small" max-height="350">
            <el-table-column type="index" label="#" width="50" />
            <el-table-column prop="action" label="操作类型" />
            <el-table-column prop="count" label="调用次数" width="100" sortable />
          </el-table>
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
import { BarChart } from 'echarts/charts'
import { TitleComponent, TooltipComponent, GridComponent } from 'echarts/components'
import VChart from 'vue-echarts'
import axios from 'axios'

use([CanvasRenderer, BarChart, TitleComponent, TooltipComponent, GridComponent])

const loading = ref(false)
const realtime = ref({})
const today = ref({})
const totals = ref({})
const apiStats = ref({})

const hourlyOption = computed(() => {
  const hours = Array.from({ length: 24 }, (_, i) => `${i}:00`)
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: hours },
    yAxis: { type: 'value' },
    series: [{
      type: 'bar',
      data: apiStats.value.hourly || [],
      itemStyle: { color: '#409eff' }
    }]
  }
})

const loadMonitor = async () => {
  try {
    const res = await axios.get('/api/admin/monitor/real-stats')
    if (res.data.code === 200) {
      realtime.value = res.data.data.realtime || {}
      today.value = res.data.data.today || {}
      totals.value = res.data.data.totals || {}
    }
  } catch (e) { console.error(e) }
}

const loadAPIStats = async () => {
  try {
    const res = await axios.get('/api/admin/monitor/api-stats')
    if (res.data.code === 200) apiStats.value = res.data.data
  } catch (e) { console.error(e) }
}

const loadAll = async () => {
  loading.value = true
  await Promise.all([loadMonitor(), loadAPIStats()])
  loading.value = false
}

onMounted(() => loadAll())
</script>

<style scoped>
.monitor-card { text-align: center; }
.monitor-card.live { border-top: 3px solid #f56c6c; }
.monitor-value { font-size: 28px; font-weight: bold; margin-bottom: 4px; }
.monitor-value.primary { color: #409eff; }
.monitor-value.success { color: #67c23a; }
.monitor-value.warning { color: #e6a23c; }
.monitor-value.info { color: #909399; }
.monitor-label { font-size: 12px; color: #909399; }
.today-item { text-align: center; }
.today-num { display: block; font-size: 24px; font-weight: bold; color: #303133; }
.today-desc { font-size: 12px; color: #909399; }
.chart { height: 350px; }
</style>

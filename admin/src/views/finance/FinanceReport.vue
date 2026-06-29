<template>
  <div>
    <h2 style="margin-bottom: 20px;">财务报表</h2>

    <!-- 报表类型切换 -->
    <el-card style="margin-bottom: 20px;">
      <el-row :gutter="10" align="middle">
        <el-col :span="12">
          <el-radio-group v-model="reportType" size="default" @change="loadReport">
            <el-radio-button value="daily">日报</el-radio-button>
            <el-radio-button value="weekly">周报</el-radio-button>
            <el-radio-button value="monthly">月报</el-radio-button>
          </el-radio-group>
        </el-col>
        <el-col :span="12" style="text-align: right;">
          <el-button type="success" @click="exportCSV">
            <el-icon><Download /></el-icon> 导出CSV
          </el-button>
        </el-col>
      </el-row>
    </el-card>

    <!-- 汇总统计 -->
    <el-row :gutter="16" style="margin-bottom: 20px;">
      <el-col :span="12">
        <el-card shadow="hover" class="summary-card">
          <div class="summary-value gold">¥{{ formatMoney(report.total_revenue) }}</div>
          <div class="summary-label">总收入</div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="hover" class="summary-card">
          <div class="summary-value primary">{{ report.total_orders || 0 }}</div>
          <div class="summary-label">总订单数</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 报表数据 -->
    <el-card>
      <template #header><span>{{ reportType === 'daily' ? '日报' : reportType === 'weekly' ? '周报' : '月报' }}明细</span></template>

      <!-- 趋势图 -->
      <v-chart class="trend-chart" :option="chartOption" autoresize style="margin-bottom: 20px;" />

      <!-- 数据表格 -->
      <el-table :data="report.reports || []" border v-loading="loading">
        <el-table-column prop="date" label="日期" width="120" />
        <el-table-column prop="order_count" label="订单数" width="100" sortable />
        <el-table-column label="收入" width="120" sortable>
          <template #default="{ row }">¥{{ formatMoney(row.revenue) }}</template>
        </el-table-column>
        <el-table-column prop="new_paid_users" label="新增付费用户" width="130" />
        <el-table-column label="操作">
          <template #default="{ row }">
            <el-button type="info" size="small" @click="showDetail(row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 详情弹窗 -->
    <el-dialog v-model="detailVisible" title="报表详情" width="500px">
      <el-descriptions :column="1" border v-if="currentDetail">
        <el-descriptions-item label="日期">{{ currentDetail.date }}</el-descriptions-item>
        <el-descriptions-item label="订单数">{{ currentDetail.order_count }}</el-descriptions-item>
        <el-descriptions-item label="收入">¥{{ formatMoney(currentDetail.revenue) }}</el-descriptions-item>
        <el-descriptions-item label="新增付费用户">{{ currentDetail.new_paid_users }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Download } from '@element-plus/icons-vue'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart, BarChart } from 'echarts/charts'
import { TitleComponent, TooltipComponent, GridComponent } from 'echarts/components'
import VChart from 'vue-echarts'
import axios from 'axios'

use([CanvasRenderer, LineChart, BarChart, TitleComponent, TooltipComponent, GridComponent])

const loading = ref(false)
const reportType = ref('daily')
const report = ref({})
const detailVisible = ref(false)
const currentDetail = ref(null)

const formatMoney = (n) => n == null ? '0.00' : (n / 100).toFixed(2)

const chartOption = computed(() => {
  const reports = report.value.reports || []
  return {
    tooltip: {
      trigger: 'axis',
      formatter: (params) => {
        let s = params[0].name + '<br/>'
        params.forEach(p => {
          s += p.seriesName + ': ' + (p.seriesName === '收入' ? '¥' + (p.value / 100).toFixed(2) : p.value) + '<br/>'
        })
        return s
      }
    },
    legend: { data: ['订单数', '收入'] },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: reports.map(r => r.date) },
    yAxis: [
      { type: 'value', name: '订单数' },
      { type: 'value', name: '收入(分)', axisLabel: { formatter: (v) => '¥' + (v / 100).toFixed(0) } }
    ],
    series: [
      { name: '订单数', type: 'bar', data: reports.map(r => r.order_count), itemStyle: { color: '#409eff' } },
      { name: '收入', type: 'line', yAxisIndex: 1, data: reports.map(r => r.revenue), smooth: true, itemStyle: { color: '#e6a23c' } }
    ]
  }
})

const loadReport = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/finance/report', { params: { type: reportType.value } })
    if (res.data.code === 200) report.value = res.data.data
  } catch (e) { console.error(e) }
  finally { loading.value = false }
}

const showDetail = (row) => {
  currentDetail.value = row
  detailVisible.value = true
}

const exportCSV = () => {
  const token = localStorage.getItem('admin_token')
  window.open(`/api/admin/finance/export?token=${token}`)
}

onMounted(() => loadReport())
</script>

<style scoped>
.summary-card { text-align: center; }
.summary-value { font-size: 32px; font-weight: bold; margin-bottom: 4px; }
.summary-value.gold { color: #e6a23c; }
.summary-value.primary { color: #409eff; }
.summary-label { font-size: 14px; color: #909399; }
.trend-chart { height: 300px; }
</style>

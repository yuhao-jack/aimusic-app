<template>
  <div>
    <h2 style="margin-bottom: 20px;">AI创作中心</h2>

    <!-- 统计卡片 -->
    <el-row :gutter="16" style="margin-bottom: 20px;">
      <el-col :span="4">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-value primary">{{ stats.total || 0 }}</div>
          <div class="stat-label">总任务数</div>
        </el-card>
      </el-col>
      <el-col :span="4">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-value success">{{ stats.success || 0 }}</div>
          <div class="stat-label">成功</div>
        </el-card>
      </el-col>
      <el-col :span="4">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-value danger">{{ stats.failed || 0 }}</div>
          <div class="stat-label">失败</div>
        </el-card>
      </el-col>
      <el-col :span="4">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-value warning">{{ stats.pending || 0 }}</div>
          <div class="stat-label">等待中</div>
        </el-card>
      </el-col>
      <el-col :span="4">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-value info">{{ stats.running || 0 }}</div>
          <div class="stat-label">处理中</div>
        </el-card>
      </el-col>
      <el-col :span="4">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-value">{{ stats.success_rate || '0' }}%</div>
          <div class="stat-label">成功率</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 今日统计 + 趋势图 -->
    <el-row :gutter="16" style="margin-bottom: 20px;">
      <el-col :span="8">
        <el-card>
          <template #header><span>今日统计</span></template>
          <div class="today-stats">
            <div class="today-item">
              <span class="today-num">{{ stats.today_total || 0 }}</span>
              <span class="today-desc">总任务</span>
            </div>
            <div class="today-item">
              <span class="today-num success">{{ stats.today_success || 0 }}</span>
              <span class="today-desc">成功</span>
            </div>
            <div class="today-item">
              <span class="today-num danger">{{ stats.today_failed || 0 }}</span>
              <span class="today-desc">失败</span>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="16">
        <el-card>
          <template #header><span>7天趋势</span></template>
          <v-chart class="trend-chart" :option="trendOption" autoresize />
        </el-card>
      </el-col>
    </el-row>

    <!-- 用户AI使用排行 -->
    <el-card style="margin-bottom: 20px;">
      <template #header><span>用户AI使用排行 Top20</span></template>
      <el-table :data="userRank" border size="small">
        <el-table-column type="index" label="排名" width="60" />
        <el-table-column prop="nickname" label="用户" width="120" />
        <el-table-column prop="total" label="总任务" width="100" sortable />
        <el-table-column prop="success" label="成功" width="100" />
        <el-table-column prop="failed" label="失败" width="100" />
        <el-table-column label="成功率" width="100">
          <template #default="{ row }">
            {{ row.total > 0 ? ((row.success / row.total) * 100).toFixed(1) : 0 }}%
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 任务列表 -->
    <el-card>
      <template #header>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span>任务列表</span>
          <div>
            <el-button type="warning" size="small" :disabled="!selectedIds.length" @click="batchRetry">
              批量重试 ({{ selectedIds.length }})
            </el-button>
            <el-button type="danger" size="small" :disabled="!selectedIds.length" @click="batchCancel">
              批量取消 ({{ selectedIds.length }})
            </el-button>
          </div>
        </div>
      </template>

      <!-- 搜索筛选 -->
      <el-row :gutter="10" style="margin-bottom: 16px;">
        <el-col :span="6">
          <el-input v-model="searchKeyword" placeholder="搜索用户ID" clearable />
        </el-col>
        <el-col :span="4">
          <el-select v-model="taskType" placeholder="任务类型" clearable>
            <el-option label="全部" value="" />
            <el-option label="歌词生成" value="1" />
            <el-option label="歌曲生成" value="2" />
            <el-option label="音色训练" value="3" />
          </el-select>
        </el-col>
        <el-col :span="4">
          <el-select v-model="taskStatus" placeholder="状态" clearable>
            <el-option label="全部" value="" />
            <el-option label="等待中" value="0" />
            <el-option label="处理中" value="1" />
            <el-option label="成功" value="2" />
            <el-option label="失败" value="3" />
          </el-select>
        </el-col>
        <el-col :span="4">
          <el-button type="primary" @click="loadData">搜索</el-button>
          <el-button @click="resetSearch">重置</el-button>
        </el-col>
      </el-row>

      <el-table :data="tableData" border v-loading="loading" @selection-change="handleSelectionChange">
        <el-table-column type="selection" width="50" />
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="user_id" label="用户ID" width="80" />
        <el-table-column prop="task_type" label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="row.task_type === 1 ? 'primary' : row.task_type === 2 ? 'success' : 'warning'">
              {{ row.task_type === 1 ? '歌词生成' : row.task_type === 2 ? '歌曲生成' : '音色训练' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="statusTypes[row.status]">
              {{ statusTexts[row.status] }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="progress" label="进度" width="100">
          <template #default="{ row }">
            <el-progress :percentage="row.progress" :stroke-width="8" />
          </template>
        </el-table-column>
        <el-table-column prop="error_msg" label="错误信息" min-width="150" show-overflow-tooltip />
        <el-table-column prop="created_at" label="创建时间" width="160" />
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button type="info" size="small" @click="showDetail(row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div style="margin-top: 16px; text-align: right;">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="loadData"
          @current-change="loadData"
        />
      </div>
    </el-card>

    <!-- 详情弹窗 -->
    <el-dialog v-model="dialogVisible" title="任务详情" width="700px">
      <el-descriptions :column="2" border v-if="currentTask">
        <el-descriptions-item label="任务ID">{{ currentTask.id }}</el-descriptions-item>
        <el-descriptions-item label="用户ID">{{ currentTask.user_id }}</el-descriptions-item>
        <el-descriptions-item label="任务类型">{{ typeTexts[currentTask.task_type] }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="statusTypes[currentTask.status]">{{ statusTexts[currentTask.status] }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="进度">{{ currentTask.progress }}%</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ currentTask.created_at }}</el-descriptions-item>
        <el-descriptions-item label="参数" :span="2">
          <pre style="margin: 0; white-space: pre-wrap;">{{ formatJSON(currentTask.params) }}</pre>
        </el-descriptions-item>
        <el-descriptions-item label="结果" :span="2">
          <pre style="margin: 0; white-space: pre-wrap;">{{ formatJSON(currentTask.result) }}</pre>
        </el-descriptions-item>
        <el-descriptions-item label="错误信息" :span="2" v-if="currentTask.error_msg">
          <span style="color: #f56c6c;">{{ currentTask.error_msg }}</span>
        </el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart } from 'echarts/charts'
import { TitleComponent, TooltipComponent, GridComponent, LegendComponent } from 'echarts/components'
import VChart from 'vue-echarts'
import axios from 'axios'

use([CanvasRenderer, LineChart, TitleComponent, TooltipComponent, GridComponent, LegendComponent])

const loading = ref(false)
const searchKeyword = ref('')
const taskType = ref('')
const taskStatus = ref('')
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const dialogVisible = ref(false)
const currentTask = ref(null)
const selectedIds = ref([])
const stats = ref({})
const userRank = ref([])

const statusTypes = { 0: 'warning', 1: 'info', 2: 'success', 3: 'danger' }
const statusTexts = { 0: '等待中', 1: '处理中', 2: '成功', 3: '失败' }
const typeTexts = { 1: '歌词生成', 2: '歌曲生成', 3: '音色训练' }

const trendOption = computed(() => {
  const trend = stats.value.trend || {}
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: trend.dates || [] },
    yAxis: { type: 'value' },
    series: [
      { name: '成功', type: 'line', data: trend.success || [], smooth: true, itemStyle: { color: '#67c23a' } },
      { name: '失败', type: 'line', data: trend.failed || [], smooth: true, itemStyle: { color: '#f56c6c' } }
    ]
  }
})

const formatJSON = (val) => {
  if (!val) return '-'
  try {
    return typeof val === 'string' ? JSON.stringify(JSON.parse(val), null, 2) : JSON.stringify(val, null, 2)
  } catch { return val }
}

const handleSelectionChange = (rows) => {
  selectedIds.value = rows.map(r => r.id)
}

const loadStats = async () => {
  try {
    const res = await axios.get('/api/admin/ai-tasks/stats')
    if (res.data.code === 200) stats.value = res.data.data
  } catch (e) { console.error(e) }
}

const loadUserRank = async () => {
  try {
    const res = await axios.get('/api/admin/ai-tasks/user-rank')
    if (res.data.code === 200) userRank.value = res.data.data
  } catch (e) { console.error(e) }
}

const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/ai-tasks', {
      params: { page: currentPage.value, page_size: pageSize.value, keyword: searchKeyword.value, type: taskType.value, status: taskStatus.value }
    })
    if (res.data.code === 200) {
      tableData.value = res.data.data.list
      total.value = res.data.data.total
    }
  } catch (e) {
    ElMessage.error('加载数据失败')
  } finally { loading.value = false }
}

const resetSearch = () => {
  searchKeyword.value = ''
  taskType.value = ''
  taskStatus.value = ''
  currentPage.value = 1
  loadData()
}

const showDetail = (row) => {
  currentTask.value = row
  dialogVisible.value = true
}

const batchRetry = async () => {
  await ElMessageBox.confirm(`确定重试${selectedIds.value.length}个失败任务？`, '提示')
  try {
    const res = await axios.post('/api/admin/ai-tasks/batch-retry', { task_ids: selectedIds.value })
    if (res.data.code === 200) {
      ElMessage.success(res.data.message)
      loadData()
      loadStats()
    }
  } catch (e) { ElMessage.error('操作失败') }
}

const batchCancel = async () => {
  await ElMessageBox.confirm(`确定取消${selectedIds.value.length}个任务？`, '提示')
  try {
    const res = await axios.post('/api/admin/ai-tasks/batch-cancel', { task_ids: selectedIds.value })
    if (res.data.code === 200) {
      ElMessage.success(res.data.message)
      loadData()
      loadStats()
    }
  } catch (e) { ElMessage.error('操作失败') }
}

onMounted(() => {
  loadStats()
  loadUserRank()
  loadData()
})
</script>

<style scoped>
.stat-card { text-align: center; }
.stat-value { font-size: 28px; font-weight: bold; margin-bottom: 4px; }
.stat-value.primary { color: #409eff; }
.stat-value.success { color: #67c23a; }
.stat-value.danger { color: #f56c6c; }
.stat-value.warning { color: #e6a23c; }
.stat-value.info { color: #909399; }
.stat-label { font-size: 13px; color: #909399; }
.today-stats { display: flex; justify-content: space-around; text-align: center; }
.today-item { display: flex; flex-direction: column; }
.today-num { font-size: 24px; font-weight: bold; }
.today-num.success { color: #67c23a; }
.today-num.danger { color: #f56c6c; }
.today-desc { font-size: 12px; color: #909399; margin-top: 4px; }
.trend-chart { height: 200px; }
</style>

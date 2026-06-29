<template>
  <div>
    <h2 style="margin-bottom: 20px;">告警管理</h2>
    <el-card>
      <!-- 筛选栏 -->
      <div style="margin-bottom: 20px; display: flex; gap: 16px;">
        <el-select v-model="filterType" placeholder="告警类型" clearable style="width: 150px;" @change="loadData">
          <el-option label="限流告警" value="rate_limit" />
          <el-option label="配额滥用" value="quota_abuse" />
          <el-option label="IP滥用" value="ip_abuse" />
        </el-select>
        <el-select v-model="filterLevel" placeholder="告警级别" clearable style="width: 120px;" @change="loadData">
          <el-option label="低" :value="1" />
          <el-option label="中" :value="2" />
          <el-option label="高" :value="3" />
        </el-select>
        <el-select v-model="filterStatus" placeholder="处理状态" clearable style="width: 120px;" @change="loadData">
          <el-option label="未处理" :value="0" />
          <el-option label="已处理" :value="1" />
        </el-select>
      </div>

      <!-- 告警列表 -->
      <el-table :data="tableData" border v-loading="loading" :row-class-name="tableRowClassName">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="type" label="类型" width="120">
          <template #default="{ row }">
            <el-tag :type="typeTagMap[row.type]">{{ typeMap[row.type] || row.type }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="level" label="级别" width="100">
          <template #default="{ row }">
            <el-tag :type="levelTagMap[row.level]">{{ levelMap[row.level] }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="target" label="目标" width="150" show-overflow-tooltip />
        <el-table-column prop="message" label="告警信息" min-width="200" show-overflow-tooltip />
        <el-table-column prop="created_at" label="时间" width="180" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 0 ? 'danger' : 'success'">
              {{ row.status === 0 ? '未处理' : '已处理' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button v-if="row.status === 0" type="primary" size="small" @click="handleAlert(row)">标记已处理</el-button>
            <span v-else style="color: #909399; font-size: 12px;">已处理</span>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div style="margin-top: 20px; text-align: right;">
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
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

// 类型映射
const typeMap = { rate_limit: '限流告警', quota_abuse: '配额滥用', ip_abuse: 'IP滥用' }
const typeTagMap = { rate_limit: 'warning', quota_abuse: 'danger', ip_abuse: 'danger' }

// 级别映射
const levelMap = { 1: '低', 2: '中', 3: '高' }
const levelTagMap = { 1: 'info', 2: 'warning', 3: 'danger' }

const loading = ref(false)
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)

// 筛选条件
const filterType = ref('')
const filterLevel = ref(null)
const filterStatus = ref(null)

// 未处理告警行高亮
const tableRowClassName = ({ row }) => {
  return row.status === 0 ? 'alert-unhandled-row' : ''
}

// 加载列表数据
const loadData = async () => {
  loading.value = true
  try {
    const params = { page: currentPage.value, page_size: pageSize.value }
    if (filterType.value) params.type = filterType.value
    if (filterLevel.value) params.level = filterLevel.value
    if (filterStatus.value !== null && filterStatus.value !== '') params.status = filterStatus.value

    const res = await axios.get('/api/admin/alerts', { params })
    if (res.data.code === 200) {
      tableData.value = res.data.data.list
      total.value = res.data.data.total
    }
  } catch (err) {
    console.error(err)
    ElMessage.error('加载数据失败')
  } finally {
    loading.value = false
  }
}

// 标记已处理
const handleAlert = (row) => {
  ElMessageBox.confirm('确定标记该告警为已处理吗？', '提示', { type: 'warning' }).then(async () => {
    try {
      const res = await axios.put(`/api/admin/alerts/${row.id}/handle`)
      if (res.data.code === 200) {
        ElMessage.success('处理成功')
        loadData()
      }
    } catch (err) {
      ElMessage.error('处理失败')
    }
  }).catch(() => {})
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
:deep(.alert-unhandled-row) {
  background-color: #fef0f0 !important;
}
:deep(.alert-unhandled-row:hover > td) {
  background-color: #fde2e2 !important;
}
</style>

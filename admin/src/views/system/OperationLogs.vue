
<template>
  <div>
    <h2 style="margin-bottom: 20px;">操作日志</h2>
    <el-card>
      <!-- 搜索区域 -->
      <el-row :gutter="10" style="margin-bottom: 20px;">
        <el-col :span="6">
          <el-input v-model="filterAdminName" placeholder="按管理员筛选" clearable />
        </el-col>
        <el-col :span="6">
          <el-select v-model="filterAction" placeholder="按操作类型筛选" clearable>
            <el-option label="全部" value="" />
            <el-option label="GET" value="GET" />
            <el-option label="POST" value="POST" />
            <el-option label="PUT" value="PUT" />
            <el-option label="DELETE" value="DELETE" />
          </el-select>
        </el-col>
        <el-col :span="4">
          <el-button type="primary" @click="loadData">搜索</el-button>
          <el-button @click="resetSearch">重置</el-button>
        </el-col>
      </el-row>

      <!-- 操作日志列表 -->
      <el-table :data="tableData" border v-loading="loading">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="admin_name" label="管理员" width="120" />
        <el-table-column prop="action" label="操作类型" width="100">
          <template #default="{ row }">
            <el-tag :type="getActionType(row.action)">{{ row.action }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="path" label="请求路径" min-width="250" show-overflow-tooltip />
        <el-table-column prop="ip" label="IP地址" width="140" />
        <el-table-column prop="created_at" label="操作时间" width="180" />
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
import { ElMessage } from 'element-plus'
import axios from 'axios'

const loading = ref(false)
const filterAdminName = ref('')
const filterAction = ref('')
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)

const getActionType = (action) => {
  const map = { GET: 'info', POST: 'success', PUT: 'warning', DELETE: 'danger' }
  return map[action] || 'info'
}

const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/system/logs', {
      params: {
        page: currentPage.value,
        page_size: pageSize.value,
        admin_name: filterAdminName.value,
        action: filterAction.value
      }
    })
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

const resetSearch = () => {
  filterAdminName.value = ''
  filterAction.value = ''
  currentPage.value = 1
  loadData()
}

onMounted(() => {
  loadData()
})
</script>

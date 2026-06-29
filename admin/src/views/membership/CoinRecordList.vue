
<template>
  <div>
    <h2 style="margin-bottom: 20px;">音币记录管理</h2>
    <el-card>
      <!-- 筛选栏 -->
      <el-row style="margin-bottom: 20px;" :gutter="16">
        <el-col :span="6">
          <el-input v-model="filters.user_id" placeholder="按用户ID筛选" clearable @clear="loadData" @keyup.enter="loadData" />
        </el-col>
        <el-col :span="6">
          <el-select v-model="filters.type" placeholder="按类型筛选" clearable @change="loadData">
            <el-option label="全部" :value="0" />
            <el-option label="充值" :value="1" />
            <el-option label="签到" :value="2" />
            <el-option label="任务奖励" :value="3" />
            <el-option label="AI消耗" :value="4" />
            <el-option label="退款" :value="5" />
          </el-select>
        </el-col>
        <el-col :span="4">
          <el-button type="primary" @click="loadData">搜索</el-button>
        </el-col>
      </el-row>

      <!-- 音币记录列表 -->
      <el-table :data="tableData" border v-loading="loading">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="user_id" label="用户ID" width="80" />
        <el-table-column prop="user_nickname" label="用户昵称" width="120" />
        <el-table-column prop="amount" label="变动数量" width="100">
          <template #default="{ row }">
            <span :style="{ color: row.amount > 0 ? '#67c23a' : '#f56c6c' }">
              {{ row.amount > 0 ? '+' : '' }}{{ row.amount }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="balance" label="变动后余额" width="100" />
        <el-table-column prop="type" label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="typeTagMap[row.type] || 'info'">
              {{ typeTextMap[row.type] || '未知' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="描述" min-width="180" show-overflow-tooltip />
        <el-table-column prop="order_no" label="关联订单号" width="160" show-overflow-tooltip />
        <el-table-column prop="created_at" label="时间" width="180">
          <template #default="{ row }">
            {{ formatTime(row.created_at) }}
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <el-pagination
        style="margin-top: 16px; justify-content: flex-end;"
        v-model:current-page="pagination.page"
        v-model:page-size="pagination.pageSize"
        :total="pagination.total"
        :page-sizes="[20, 50, 100]"
        layout="total, sizes, prev, pager, next"
        @size-change="loadData"
        @current-change="loadData"
      />
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

const loading = ref(false)
const tableData = ref([])

const filters = reactive({
  user_id: '',
  type: 0
})

const pagination = reactive({
  page: 1,
  pageSize: 20,
  total: 0
})

// 类型文本映射
const typeTextMap = {
  1: '充值',
  2: '签到',
  3: '任务奖励',
  4: 'AI消耗',
  5: '退款'
}

// 类型标签颜色映射
const typeTagMap = {
  1: 'success',
  2: 'primary',
  3: 'warning',
  4: 'danger',
  5: 'info'
}

// 格式化时间
const formatTime = (t) => {
  if (!t) return ''
  const d = new Date(t)
  return d.toLocaleString('zh-CN', { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit' })
}

// 加载数据
const loadData = async () => {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      page_size: pagination.pageSize
    }
    if (filters.user_id) {
      params.user_id = filters.user_id
    }
    if (filters.type > 0) {
      params.type = filters.type
    }
    const res = await axios.get('/api/admin/coin-records', { params })
    if (res.data.code === 200) {
      tableData.value = res.data.data.list || []
      pagination.total = res.data.data.total || 0
    }
  } catch (err) {
    console.error(err)
    ElMessage.error('加载数据失败')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadData()
})
</script>

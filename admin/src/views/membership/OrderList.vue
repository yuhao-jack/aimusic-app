
<template>
  <div>
    <h2 style="margin-bottom: 20px;">订单管理</h2>
    <el-card>
      <!-- 搜索区域 -->
      <el-row :gutter="10" style="margin-bottom: 20px;">
        <el-col :span="8">
          <el-input v-model="searchKeyword" placeholder="搜索订单号" clearable />
        </el-col>
        <el-col :span="4">
          <el-select v-model="filterStatus" placeholder="订单状态" clearable>
            <el-option label="全部" value="" />
            <el-option label="待支付" value="pending" />
            <el-option label="已支付" value="paid" />
            <el-option label="已取消" value="cancelled" />
          </el-select>
        </el-col>
        <el-col :span="4">
          <el-button type="primary" @click="loadData">搜索</el-button>
          <el-button @click="resetSearch">重置</el-button>
        </el-col>
        <el-col :span="8" style="text-align: right;">
          <el-button type="warning" @click="exportOrders">导出订单</el-button>
        </el-col>
      </el-row>

      <!-- 订单列表 -->
      <el-table :data="tableData" border v-loading="loading">
        <el-table-column prop="order_no" label="订单号" width="200" />
        <el-table-column prop="user_id" label="用户ID" width="80" />
        <el-table-column prop="type" label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="row.type === 'vip' ? 'warning' : 'success'">
              {{ row.type === 'vip' ? 'VIP' : '音币' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="amount" label="金额（元）" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getOrderStatusType(row.status)">
              {{ getOrderStatusLabel(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="pay_method" label="支付方式" width="100" />
        <el-table-column prop="created_at" label="创建时间" width="180" />
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
const searchKeyword = ref('')
const filterStatus = ref('')
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)

// 获取订单状态标签类型
const getOrderStatusType = (status) => {
  const map = { pending: 'warning', paid: 'success', cancelled: 'info' }
  return map[status] || 'info'
}

// 获取订单状态显示文本
const getOrderStatusLabel = (status) => {
  const map = { pending: '待支付', paid: '已支付', cancelled: '已取消' }
  return map[status] || status
}

// 加载数据
const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/orders', {
      params: {
        page: currentPage.value,
        page_size: pageSize.value,
        keyword: searchKeyword.value,
        status: filterStatus.value
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

// 重置搜索
const resetSearch = () => {
  searchKeyword.value = ''
  filterStatus.value = ''
  currentPage.value = 1
  loadData()
}

// 导出订单列表
const exportOrders = () => {
  window.open('/api/admin/export/orders', '_blank')
}

onMounted(() => {
  loadData()
})
</script>

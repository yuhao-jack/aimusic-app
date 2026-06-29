<template>
  <div>
    <h2 style="margin-bottom: 20px;">订单管理</h2>
    <el-card>
      <el-row :gutter="10" style="margin-bottom: 20px;">
        <el-col :span="8">
          <el-input v-model="searchKeyword" placeholder="搜索订单号" clearable />
        </el-col>
        <el-col :span="4">
          <el-select v-model="filterStatus" placeholder="订单状态" clearable>
            <el-option label="全部" value="" />
            <el-option label="待支付" value="0" />
            <el-option label="已支付" value="1" />
            <el-option label="已取消" value="2" />
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

      <el-table :data="tableData" border v-loading="loading">
        <el-table-column prop="order_no" label="订单号" width="200" />
        <el-table-column prop="user_id" label="用户ID" width="80" />
        <el-table-column label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="row.level === 2 ? 'danger' : 'warning'">
              {{ row.level === 2 ? 'SVIP' : 'VIP' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="金额（元）" width="100">
          <template #default="{ row }">{{ (row.amount / 100).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="statusTypes[row.status]">
              {{ statusLabels[row.status] }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="pay_method" label="支付方式" width="100" />
        <el-table-column prop="created_at" label="创建时间" width="180" />
      </el-table>

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

const statusTypes = { 0: 'warning', 1: 'success', 2: 'info' }
const statusLabels = { 0: '待支付', 1: '已支付', 2: '已取消' }

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
  } catch (e) { ElMessage.error('加载失败') }
  finally { loading.value = false }
}

const resetSearch = () => {
  searchKeyword.value = ''
  filterStatus.value = ''
  currentPage.value = 1
  loadData()
}

const exportOrders = () => {
  const token = localStorage.getItem('admin_token')
  window.open(`/api/admin/export/orders?token=${token}`)
}

onMounted(() => loadData())
</script>


<template>
  <div>
    <h2 style="margin-bottom: 20px;">邀请记录管理</h2>
    <el-card>
      <!-- 搜索区域 -->
      <el-row :gutter="10" style="margin-bottom: 20px;">
        <el-col :span="6">
          <el-input v-model="filterInviterId" placeholder="按邀请者ID筛选" clearable />
        </el-col>
        <el-col :span="6">
          <el-select v-model="filterStatus" placeholder="按状态筛选" clearable>
            <el-option label="全部" value="" />
            <el-option label="待注册" :value="0" />
            <el-option label="已注册" :value="1" />
            <el-option label="已奖励" :value="2" />
          </el-select>
        </el-col>
        <el-col :span="4">
          <el-button type="primary" @click="loadData">搜索</el-button>
          <el-button @click="resetSearch">重置</el-button>
        </el-col>
      </el-row>

      <!-- 邀请记录列表 -->
      <el-table :data="tableData" border v-loading="loading">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="inviter_id" label="邀请者ID" width="100" />
        <el-table-column prop="invite_code" label="邀请码" width="150" />
        <el-table-column prop="invitee_id" label="被邀请者ID" width="110">
          <template #default="{ row }">
            {{ row.invitee_id || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="reward" label="奖励音币" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getInviteStatusType(row.status)">
              {{ getInviteStatusLabel(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
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
const filterInviterId = ref('')
const filterStatus = ref('')
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)

const getInviteStatusType = (status) => {
  const map = { 0: 'info', 1: 'warning', 2: 'success' }
  return map[status] || 'info'
}

const getInviteStatusLabel = (status) => {
  const map = { 0: '待注册', 1: '已注册', 2: '已奖励' }
  return map[status] || '未知'
}

const loadData = async () => {
  loading.value = true
  try {
    const params = {
      page: currentPage.value,
      page_size: pageSize.value
    }
    if (filterInviterId.value) {
      params.inviter_id = filterInviterId.value
    }
    if (filterStatus.value !== '' && filterStatus.value !== null) {
      params.status = filterStatus.value
    }
    const res = await axios.get('/api/admin/invites', { params })
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
  filterInviterId.value = ''
  filterStatus.value = ''
  currentPage.value = 1
  loadData()
}

onMounted(() => {
  loadData()
})
</script>

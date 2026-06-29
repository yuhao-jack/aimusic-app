<template>
  <div>
    <h2 style="margin-bottom: 20px;">关注关系管理</h2>
    <el-card>
      <el-row :gutter="10" style="margin-bottom: 16px;">
        <el-col :span="8">
          <el-input v-model="searchUserId" placeholder="输入用户ID查询关注关系" clearable />
        </el-col>
        <el-col :span="4">
          <el-button type="primary" @click="loadData">查询</el-button>
          <el-button @click="searchUserId=''; loadData()">重置</el-button>
        </el-col>
      </el-row>

      <el-table :data="tableData" border v-loading="loading">
        <template #empty><el-empty description="暂无数据" /></template>
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="follower_id" label="关注者ID" width="100" />
        <el-table-column prop="following_id" label="被关注者ID" width="100" />
        <el-table-column prop="created_at" label="关注时间" width="160" />
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button type="danger" size="small" @click="deleteItem(row)">解除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div style="margin-top: 16px; text-align: right;">
        <el-pagination v-model:current-page="currentPage" v-model:page-size="pageSize" :page-sizes="[10,20,50]" :total="total" layout="total, sizes, prev, pager, next" @size-change="loadData" @current-change="loadData" />
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

const loading = ref(false)
const searchUserId = ref('')
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)

const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/follows', { params: { page: currentPage.value, page_size: pageSize.value, user_id: searchUserId.value } })
    if (res.data.code === 200) { tableData.value = res.data.data.list; total.value = res.data.data.total }
  } catch (e) { ElMessage.error('加载失败') }
  finally { loading.value = false }
}

const deleteItem = async (row) => {
  await ElMessageBox.confirm('确定解除该关注关系？', '提示')
  try {
    await axios.delete(`/api/admin/follows/${row.id}`)
    ElMessage.success('已解除')
    loadData()
  } catch (e) { ElMessage.error('操作失败') }
}

onMounted(() => loadData())
</script>

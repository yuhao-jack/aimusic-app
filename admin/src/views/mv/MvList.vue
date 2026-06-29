<template>
  <div>
    <h2 style="margin-bottom: 20px;">MV管理</h2>
    <el-card>
      <el-table :data="tableData" border v-loading="loading">
        <template #empty><el-empty description="暂无数据" /></template>
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="user_id" label="用户ID" width="80" />
        <el-table-column prop="title" label="标题" min-width="150" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : row.status === 0 ? 'warning' : 'danger'">
              {{ row.status === 1 ? '已完成' : row.status === 0 ? '生成中' : '失败' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="160" />
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button type="danger" size="small" @click="deleteItem(row)">删除</el-button>
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
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)

const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/mvs', { params: { page: currentPage.value, page_size: pageSize.value } })
    if (res.data.code === 200) { tableData.value = res.data.data.list; total.value = res.data.data.total }
  } catch (e) { ElMessage.error('加载失败') }
  finally { loading.value = false }
}

const deleteItem = async (row) => {
  await ElMessageBox.confirm('确定删除该MV？', '提示')
  try {
    await axios.delete(`/api/admin/mvs/${row.id}`)
    ElMessage.success('删除成功')
    loadData()
  } catch (e) { ElMessage.error('删除失败') }
}

onMounted(() => loadData())
</script>

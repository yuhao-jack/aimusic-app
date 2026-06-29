
<template>
  <div>
    <h2 style="margin-bottom: 20px;">一起听房间管理</h2>
    <el-card>
      <!-- 筛选 -->
      <el-row :gutter="10" style="margin-bottom: 20px;">
        <el-col :span="6">
          <el-select v-model="status" placeholder="房间状态" clearable>
            <el-option label="全部" value="" />
            <el-option label="活跃" :value="1" />
            <el-option label="关闭" :value="0" />
          </el-select>
        </el-col>
        <el-col :span="4">
          <el-button type="primary" @click="loadData">查询</el-button>
          <el-button @click="resetSearch">重置</el-button>
        </el-col>
      </el-row>

      <el-table :data="tableData" border v-loading="loading">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="room_code" label="邀请码" width="100" />
        <el-table-column prop="song_title" label="当前歌曲" width="180" />
        <el-table-column prop="owner_nickname" label="创建者" width="120" />
        <el-table-column prop="member_count" label="成员数" width="80" />
        <el-table-column prop="status" label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'">
              {{ row.status === 1 ? '活跃' : '关闭' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="160" />
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button v-if="row.status === 1" type="danger" size="small" @click="closeRoom(row)">关闭房间</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div style="margin-top: 20px; text-align: right;">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50]"
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

const loading = ref(false)
const status = ref('')
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)

const loadData = async () => {
  loading.value = true
  try {
    const params = {
      page: currentPage.value,
      page_size: pageSize.value
    }
    if (status.value !== '') {
      params.status = status.value
    }
    const res = await axios.get('/api/admin/together-rooms', { params })
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
  status.value = ''
  currentPage.value = 1
  loadData()
}

const closeRoom = async (row) => {
  try {
    await ElMessageBox.confirm('确认关闭该房间吗？', '提示')
    await axios.post(`/api/admin/together-rooms/${row.id}/close`)
    ElMessage.success('关闭成功')
    loadData()
  } catch (err) {
    if (err !== 'cancel') {
      ElMessage.error('操作失败')
    }
  }
}

onMounted(() => {
  loadData()
})
</script>


<template>
  <div>
    <h2 style="margin-bottom: 20px;">评论管理</h2>
    <el-card>
      <!-- 搜索筛选 -->
      <el-row :gutter="10" style="margin-bottom: 20px;">
        <el-col :span="8">
          <el-input v-model="searchKeyword" placeholder="搜索评论内容" clearable />
        </el-col>
        <el-col :span="4">
          <el-button type="primary" @click="loadData">搜索</el-button>
          <el-button @click="resetSearch">重置</el-button>
        </el-col>
      </el-row>

      <el-table :data="tableData" border v-loading="loading">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="user_nickname" label="用户" width="120" />
        <el-table-column prop="song_title" label="歌曲" width="150" />
        <el-table-column prop="content" label="评论内容" min-width="200" show-overflow-tooltip />
        <el-table-column prop="like_count" label="点赞" width="60" />
        <el-table-column prop="created_at" label="时间" width="160" />
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button type="danger" size="small" @click="deleteComment(row)">删除</el-button>
          </template>
        </el-table-column>
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
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

const loading = ref(false)
const searchKeyword = ref('')
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)

const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/comments', {
      params: {
        page: currentPage.value,
        page_size: pageSize.value,
        keyword: searchKeyword.value
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
  searchKeyword.value = ''
  currentPage.value = 1
  loadData()
}

const deleteComment = async (row) => {
  try {
    await ElMessageBox.confirm('确认删除该评论吗？', '提示')
    const res = await axios.delete(`/api/admin/comments/${row.id}`)
    if (res.data.code === 200) {
      ElMessage.success('删除成功')
      loadData()
    } else {
      ElMessage.error(res.data.message || '删除失败')
    }
  } catch (err) {
    if (err !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

onMounted(() => {
  loadData()
})
</script>

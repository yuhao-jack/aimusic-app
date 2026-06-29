
<template>
  <div>
    <h2 style="margin-bottom: 20px;">用户动态管理</h2>
    <el-card>
      <!-- 搜索筛选 -->
      <el-row :gutter="10" style="margin-bottom: 20px;">
        <el-col :span="6">
          <el-input v-model="searchKeyword" placeholder="搜索内容关键词" clearable />
        </el-col>
        <el-col :span="6">
          <el-input-number v-model="userId" placeholder="用户ID" :min="0" />
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
        <el-table-column prop="content" label="动态内容" min-width="200" show-overflow-tooltip />
        <el-table-column prop="like_count" label="点赞" width="60" />
        <el-table-column prop="comment_count" label="评论" width="60" />
        <el-table-column prop="created_at" label="发布时间" width="160" />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="showDetail(row)">详情</el-button>
            <el-button type="danger" size="small" @click="deletePost(row)">删除</el-button>
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

    <!-- 详情弹窗 -->
    <el-dialog v-model="dialogVisible" title="动态详情" width="600px">
      <div v-if="currentPost">
        <p><strong>发布用户：</strong>{{ currentPost.user_nickname }} (ID: {{ currentPost.user_id }})</p>
        <p><strong>发布时间：</strong>{{ currentPost.created_at }}</p>
        <p><strong>内容：</strong></p>
        <p>{{ currentPost.content }}</p>
        <p v-if="currentPost.images && currentPost.images.length > 0">
          <strong>图片：</strong>{{ currentPost.images.length }}张
        </p>
        <p><strong>点赞数：</strong>{{ currentPost.like_count }} &nbsp;&nbsp; 评论数：{{ currentPost.comment_count }}</p>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

const loading = ref(false)
const searchKeyword = ref('')
const userId = ref(0)
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const dialogVisible = ref(false)
const currentPost = ref(null)

const loadData = async () => {
  loading.value = true
  try {
    const params = {
      page: currentPage.value,
      page_size: pageSize.value,
      keyword: searchKeyword.value
    }
    if (userId.value > 0) {
      params.user_id = userId.value
    }
    const res = await axios.get('/api/admin/posts', { params })
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
  userId.value = 0
  currentPage.value = 1
  loadData()
}

const showDetail = (row) => {
  currentPost.value = row
  dialogVisible.value = true
}

const deletePost = async (row) => {
  try {
    await ElMessageBox.confirm('确认删除该动态吗？删除后无法恢复', '提示')
    const res = await axios.delete(`/api/admin/posts/${row.id}`)
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

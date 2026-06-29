
<template>
  <div>
    <h2 style="margin-bottom: 20px;">AI创作管理</h2>
    <el-card>
      <!-- 搜索筛选 -->
      <el-row :gutter="10" style="margin-bottom: 20px;">
        <el-col :span="6">
          <el-input v-model="searchKeyword" placeholder="搜索用户ID或内容关键词" clearable />
        </el-col>
        <el-col :span="6">
          <el-select v-model="taskType" placeholder="任务类型" clearable>
            <el-option label="全部" value="" />
            <el-option label="歌词生成" value="lyric" />
            <el-option label="歌曲生成" value="song" />
          </el-select>
        </el-col>
        <el-col :span="4">
          <el-button type="primary" @click="loadData">搜索</el-button>
          <el-button @click="resetSearch">重置</el-button>
        </el-col>
      </el-row>

      <!-- 任务列表 -->
      <el-table :data="tableData" border v-loading="loading">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="user_id" label="用户ID" width="80" />
        <el-table-column prop="type" label="类型" width="100">
          <template #default="{ row }">
            {{ row.type === 'lyric' ? '歌词生成' : '歌曲生成' }}
          </template>
        </el-table-column>
        <el-table-column prop="prompt" label="创作提示" min-width="200" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : row.status === 0 ? 'warning' : 'danger'">
              {{ row.status === 1 ? '完成' : row.status === 0 ? '处理中' : '失败' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="160" />
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="info" size="small" @click="showDetail(row)">查看详情</el-button>
          </template>
        </el-table-column>
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

    <!-- 详情弹窗 -->
    <el-dialog v-model="dialogVisible" title="创作详情" width="600px">
      <div v-if="currentTask">
        <p><strong>用户ID：</strong>{{ currentTask.user_id }}</p>
        <p><strong>任务类型：</strong>{{ currentTask.type === 'lyric' ? '歌词生成' : '歌曲生成' }}</p>
        <p><strong>创作提示：</strong>{{ currentTask.prompt }}</p>
        <p><strong>结果：</strong></p>
        <el-input v-model="currentTask.result" type="textarea" :rows="10" disabled />
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

const loading = ref(false)
const searchKeyword = ref('')
const taskType = ref('')
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const dialogVisible = ref(false)
const currentTask = ref(null)

const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/ai-tasks', {
      params: {
        page: currentPage.value,
        page_size: pageSize.value,
        keyword: searchKeyword.value,
        type: taskType.value
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
  taskType.value = ''
  currentPage.value = 1
  loadData()
}

const showDetail = (row) => {
  currentTask.value = row
  dialogVisible.value = true
}

onMounted(() => {
  loadData()
})
</script>

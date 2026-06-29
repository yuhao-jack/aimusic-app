
<template>
  <div>
    <h2 style="margin-bottom: 20px;">音乐日记管理</h2>
    <el-card>
      <!-- 搜索区域 -->
      <el-row :gutter="10" style="margin-bottom: 20px;">
        <el-col :span="6">
          <el-input v-model="filterUserId" placeholder="按用户ID筛选" clearable />
        </el-col>
        <el-col :span="6">
          <el-select v-model="filterMood" placeholder="按心情筛选" clearable>
            <el-option label="全部" value="" />
            <el-option label="开心" value="开心" />
            <el-option label="难过" value="难过" />
            <el-option label="平静" value="平静" />
            <el-option label="兴奋" value="兴奋" />
            <el-option label="思念" value="思念" />
            <el-option label="孤独" value="孤独" />
          </el-select>
        </el-col>
        <el-col :span="4">
          <el-button type="primary" @click="loadData">搜索</el-button>
          <el-button @click="resetSearch">重置</el-button>
        </el-col>
      </el-row>

      <!-- 日记列表 -->
      <el-table :data="tableData" border v-loading="loading">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="user_id" label="用户ID" width="80" />
        <el-table-column prop="user_nickname" label="昵称" width="120" />
        <el-table-column prop="content" label="内容" min-width="200" show-overflow-tooltip />
        <el-table-column prop="mood" label="心情" width="80">
          <template #default="{ row }">
            <el-tag v-if="row.mood" type="info">{{ row.mood }}</el-tag>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="song_title" label="关联歌曲" width="150" show-overflow-tooltip>
          <template #default="{ row }">
            {{ row.song_title || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="is_public" label="可见性" width="80">
          <template #default="{ row }">
            <el-tag :type="row.is_public ? 'success' : 'warning'">
              {{ row.is_public ? '公开' : '私密' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180" />
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button type="danger" size="small" @click="deleteDiary(row)">删除</el-button>
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
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

const loading = ref(false)
const filterUserId = ref('')
const filterMood = ref('')
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)

const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/diaries', {
      params: {
        page: currentPage.value,
        page_size: pageSize.value,
        user_id: filterUserId.value || 0,
        mood: filterMood.value
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
  filterUserId.value = ''
  filterMood.value = ''
  currentPage.value = 1
  loadData()
}

const deleteDiary = async (row) => {
  try {
    await ElMessageBox.confirm('确认删除该日记吗？删除后无法恢复', '提示')
    const res = await axios.delete(`/api/admin/diaries/${row.id}`)
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

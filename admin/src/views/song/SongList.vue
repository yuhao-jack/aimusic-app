
<template>
  <div>
    <h2 style="margin-bottom: 20px;">音乐管理</h2>
    <el-card>
      <!-- 搜索区域 -->
      <el-row :gutter="10" style="margin-bottom: 20px;">
        <el-col :span="8">
          <el-input v-model="searchKeyword" placeholder="搜索歌曲名/歌手" clearable />
        </el-col>
        <el-col :span="8">
          <el-button type="primary" @click="loadData">搜索</el-button>
          <el-button @click="resetSearch">重置</el-button>
          <el-button type="success" @click="showCreateDialog">新增歌曲</el-button>
        </el-col>
        <el-col :span="8" style="text-align: right;">
          <el-button type="warning" @click="exportSongs">导出歌曲</el-button>
        </el-col>
      </el-row>

      <!-- 歌曲列表 -->
      <el-table :data="tableData" border v-loading="loading">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="title" label="歌曲名" width="180" />
        <el-table-column prop="singer" label="歌手" width="150" />
        <el-table-column prop="album" label="专辑" width="150" />
        <el-table-column prop="duration" label="时长" width="80" />
        <el-table-column prop="play_count" label="播放量" width="80" />
        <el-table-column prop="status" label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="statusTypes[row.status]">
              {{ statusLabels[row.status] }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="160" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="showEditDialog(row)">编辑</el-button>
            <el-button :type="row.status === 1 ? 'warning' : 'success'" size="small" @click="toggleStatus(row)">
              {{ row.status === 1 ? '下架' : '上架' }}
            </el-button>
            <el-button type="danger" size="small" @click="deleteSong(row)">删除</el-button>
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

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="isCreate ? '新增歌曲' : '编辑歌曲'" width="600px">
      <el-form ref="formRef" :model="form" :rules="formRules" label-width="80px">
        <el-form-item label="歌曲名" prop="title">
          <el-input v-model="form.title" placeholder="请输入歌曲名" />
        </el-form-item>
        <el-form-item label="歌手" prop="singer">
          <el-input v-model="form.singer" placeholder="请输入歌手名" />
        </el-form-item>
        <el-form-item label="专辑">
          <el-input v-model="form.album" placeholder="请输入专辑名" />
        </el-form-item>
        <el-form-item label="封面URL">
          <el-input v-model="form.cover_url" placeholder="请输入封面图片URL" />
        </el-form-item>
        <el-form-item label="歌曲文件URL">
          <el-input v-model="form.file_url" placeholder="请输入歌曲文件URL" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveForm">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

const loading = ref(false)
const searchKeyword = ref('')
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const dialogVisible = ref(false)
const isCreate = ref(true)
const form = ref({})
const formRef = ref(null)
const formRules = {
  title: [{ required: true, message: '请输入歌曲名', trigger: 'blur' }],
  singer: [{ required: true, message: '请输入歌手名', trigger: 'blur' }]
}

const statusTypes = { 0: 'warning', 1: 'success', 2: 'danger' }
const statusLabels = { 0: '审核中', 1: '上架', 2: '下架' }

const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/songs', {
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

// 导出歌曲列表
const exportSongs = () => {
  window.open('/api/admin/export/songs', '_blank')
}

const showCreateDialog = () => {
  form.value = {}
  isCreate.value = true
  dialogVisible.value = true
}

const showEditDialog = (row) => {
  form.value = { ...row }
  isCreate.value = false
  dialogVisible.value = true
}

const saveForm = async () => {
  if (formRef.value) {
    const valid = await formRef.value.validate().catch(() => false)
    if (!valid) return
  }
  try {
    let res
    if (isCreate.value) {
      res = await axios.post('/api/admin/songs', form.value)
    } else {
      res = await axios.put(`/api/admin/songs/${form.value.id}`, form.value)
    }
    if (res.data.code === 200) {
      ElMessage.success(isCreate.value ? '新增成功' : '更新成功')
      dialogVisible.value = false
      loadData()
    } else {
      ElMessage.error(res.data.message || '保存失败')
    }
  } catch (err) {
    ElMessage.error('保存失败')
  }
}

const toggleStatus = async (row) => {
  try {
    const newStatus = row.status === 1 ? 0 : 1
    const actionText = row.status === 1 ? '下架' : '上架'
    await ElMessageBox.confirm(`确认${actionText}该歌曲吗？`, '提示', { type: 'warning' })
    const res = await axios.put(`/api/admin/songs/${row.id}`, {
      ...row,
      status: newStatus
    })
    if (res.data.code === 200) {
      ElMessage.success('操作成功')
      loadData()
    } else {
      ElMessage.error(res.data.message || '操作失败')
    }
  } catch (err) {
    if (err !== 'cancel') {
      ElMessage.error('操作失败')
    }
  }
}

const deleteSong = async (row) => {
  try {
    await ElMessageBox.confirm('确认删除该歌曲吗？删除后无法恢复', '提示')
    const res = await axios.delete(`/api/admin/songs/${row.id}`)
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

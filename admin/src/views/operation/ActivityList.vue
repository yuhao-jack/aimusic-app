<template>
  <div>
    <h2 style="margin-bottom: 20px;">活动/公告管理</h2>
    <el-card>
      <!-- 操作栏 -->
      <div style="margin-bottom: 20px; display: flex; justify-content: space-between;">
        <div>
          <el-button type="primary" @click="showAddDialog">新增活动</el-button>
          <el-select v-model="typeFilter" placeholder="类型筛选" style="margin-left: 10px; width: 120px;" @change="loadData">
            <el-option label="全部" value="0" />
            <el-option label="公告" value="1" />
            <el-option label="活动" value="2" />
            <el-option label="比赛" value="3" />
          </el-select>
        </div>
      </div>

      <!-- 活动列表 -->
      <el-table :data="tableData" border v-loading="loading">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="title" label="标题" width="180" show-overflow-tooltip />
        <el-table-column label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="typeTagMap[row.type]?.type || 'info'">
              {{ typeTagMap[row.type]?.text || '未知' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="封面" width="120">
          <template #default="{ row }">
            <el-image
              v-if="row.cover"
              :src="row.cover"
              :preview-src-list="[row.cover]"
              style="width: 80px; height: 45px;"
              fit="cover"
            />
            <span v-else>无封面</span>
          </template>
        </el-table-column>
        <el-table-column prop="start_at" label="开始时间" width="180">
          <template #default="{ row }">
            {{ row.start_at ? formatTimestamp(row.start_at) : '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="end_at" label="结束时间" width="180">
          <template #default="{ row }">
            {{ row.end_at ? formatTimestamp(row.end_at) : '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="sort_order" label="排序" width="80" />
        <el-table-column prop="is_active" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.is_active ? 'success' : 'danger'">
              {{ row.is_active ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="showEditDialog(row)">编辑</el-button>
            <el-button type="danger" size="small" @click="handleDelete(row)">删除</el-button>
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
    <el-dialog v-model="dialogVisible" :title="isEdit ? '编辑活动' : '新增活动'" width="650px">
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
        <el-form-item label="标题" prop="title">
          <el-input v-model="formData.title" placeholder="请输入标题" />
        </el-form-item>
        <el-form-item label="类型" prop="type">
          <el-select v-model="formData.type" placeholder="请选择类型">
            <el-option label="公告" :value="1" />
            <el-option label="活动" :value="2" />
            <el-option label="比赛" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="封面图URL">
          <el-input v-model="formData.cover" placeholder="请输入封面图地址" />
        </el-form-item>
        <el-form-item label="内容" prop="content">
          <el-input v-model="formData.content" type="textarea" :rows="6" placeholder="请输入活动内容" />
        </el-form-item>
        <el-form-item label="开始时间">
          <el-date-picker v-model="formData.start_at" type="datetime" placeholder="选择开始时间" value-format="X" />
        </el-form-item>
        <el-form-item label="结束时间">
          <el-date-picker v-model="formData.end_at" type="datetime" placeholder="选择结束时间" value-format="X" />
        </el-form-item>
        <el-form-item label="排序值">
          <el-input-number v-model="formData.sort_order" :min="0" :max="9999" />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="formData.is_active" active-text="启用" inactive-text="禁用" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSave">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

// 类型标签映射
const typeTagMap = {
  1: { text: '公告', type: 'info' },
  2: { text: '活动', type: 'success' },
  3: { text: '比赛', type: 'warning' }
}

// 格式化时间戳
const formatTimestamp = (timestamp) => {
  if (!timestamp) return '-'
  const date = new Date(timestamp * 1000)
  return date.toLocaleString('zh-CN', {
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit'
  })
}

const loading = ref(false)
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const typeFilter = ref('0')
const dialogVisible = ref(false)
const isEdit = ref(false)
const formData = ref({
  title: '',
  content: '',
  cover: '',
  type: 1,
  start_at: '',
  end_at: '',
  is_active: true,
  sort_order: 0
})
const formRef = ref(null)
const formRules = {
  title: [{ required: true, message: '请输入标题', trigger: 'blur' }],
  content: [{ required: true, message: '请输入内容', trigger: 'blur' }],
  type: [{ required: true, message: '请选择类型', trigger: 'change' }]
}

// 加载列表数据
const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/activities', {
      params: {
        page: currentPage.value,
        page_size: pageSize.value,
        type: typeFilter.value
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

// 重置表单
const resetForm = () => {
  formData.value = {
    title: '',
    content: '',
    cover: '',
    type: 1,
    start_at: '',
    end_at: '',
    is_active: true,
    sort_order: 0
  }
}

// 显示新增弹窗
const showAddDialog = () => {
  resetForm()
  isEdit.value = false
  dialogVisible.value = true
}

// 显示编辑弹窗
const showEditDialog = (row) => {
  formData.value = { ...row }
  isEdit.value = true
  dialogVisible.value = true
}

// 保存（新增/编辑）
const handleSave = async () => {
  if (formRef.value) {
    const valid = await formRef.value.validate().catch(() => false)
    if (!valid) return
  }
  try {
    let res
    if (isEdit.value) {
      res = await axios.put(`/api/admin/activities/${formData.value.id}`, formData.value)
    } else {
      res = await axios.post('/api/admin/activities', formData.value)
    }
    if (res.data.code === 200) {
      ElMessage.success(isEdit.value ? '编辑成功' : '新增成功')
      dialogVisible.value = false
      loadData()
    } else {
      ElMessage.error(res.data.message || '操作失败')
    }
  } catch (err) {
    ElMessage.error('操作失败')
  }
}

// 删除
const handleDelete = (row) => {
  ElMessageBox.confirm('确定删除该活动吗？', '提示', { type: 'warning' }).then(async () => {
    try {
      const res = await axios.delete(`/api/admin/activities/${row.id}`)
      if (res.data.code === 200) {
        ElMessage.success('删除成功')
        loadData()
      }
    } catch (err) {
      ElMessage.error('删除失败')
    }
  }).catch(() => {})
}

onMounted(() => {
  loadData()
})
</script>
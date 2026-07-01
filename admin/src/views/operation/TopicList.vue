
<template>
  <div>
    <h2 style="margin-bottom: 20px;">话题管理</h2>
    <el-card>
      <div style="margin-bottom: 20px;">
        <el-button type="primary" @click="showAddDialog">新增话题</el-button>
      </div>

      <el-table :data="tableData" border v-loading="loading">
        <template #empty><el-empty description="暂无数据" /></template>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="name" label="名称" width="180" />
        <el-table-column label="图标" width="100">
          <template #default="{ row }">
            <el-image v-if="row.icon" :src="row.icon" style="width: 40px; height: 40px;" fit="cover" />
            <span v-else>无图标</span>
          </template>
        </el-table-column>
        <el-table-column prop="post_count" label="关联动态数" width="120" />
        <el-table-column prop="sort_order" label="排序" width="100" />
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

      <div style="margin-top: 20px; text-align: right;">
        <el-pagination v-model:current-page="currentPage" v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]" :total="total"
          layout="total, sizes, prev, pager, next, jumper" @size-change="loadData" @current-change="loadData" />
      </div>
    </el-card>

    <el-dialog v-model="dialogVisible" :title="isEdit ? '编辑话题' : '新增话题'" width="500px">
      <el-form :model="formData" label-width="100px">
        <el-form-item label="话题名称" required>
          <el-input v-model="formData.name" placeholder="请输入话题名称" />
        </el-form-item>
        <el-form-item label="图标URL">
          <el-input v-model="formData.icon" placeholder="请输入图标地址" />
        </el-form-item>
        <el-form-item label="排序值">
          <el-input-number v-model="formData.sort_order" :min="0" :max="9999" />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="formData.is_active" />
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

const loading = ref(false)
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const dialogVisible = ref(false)
const isEdit = ref(false)
const formData = ref({ name: '', icon: '', sort_order: 0, is_active: true })

const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/topics', {
      params: { page: currentPage.value, page_size: pageSize.value }
    })
    if (res.data.code === 200) {
      tableData.value = res.data.data.list || res.data.data
      total.value = res.data.data.total || tableData.value.length
    }
  } catch (e) { ElMessage.error('加载失败') }
  finally { loading.value = false }
}

const showAddDialog = () => {
  isEdit.value = false
  formData.value = { name: '', icon: '', sort_order: 0, is_active: true }
  dialogVisible.value = true
}

const showEditDialog = (row) => {
  isEdit.value = true
  formData.value = { ...row }
  dialogVisible.value = true
}

const handleSave = async () => {
  try {
    if (isEdit.value) {
      await axios.put(`/api/admin/topics/${formData.value.id}`, formData.value)
    } else {
      await axios.post('/api/admin/topics', formData.value)
    }
    ElMessage.success(isEdit.value ? '更新成功' : '创建成功')
    dialogVisible.value = false
    loadData()
  } catch (e) { ElMessage.error('操作失败') }
}

const handleDelete = async (row) => {
  await ElMessageBox.confirm('确定删除该话题？', '提示')
  try {
    await axios.delete(`/api/admin/topics/${row.id}`)
    ElMessage.success('删除成功')
    loadData()
  } catch (e) { ElMessage.error('删除失败') }
}

onMounted(() => loadData())
</script>

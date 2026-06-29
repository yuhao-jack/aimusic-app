<template>
  <div>
    <h2 style="margin-bottom: 20px;">广告位管理</h2>
    <el-card>
      <template #header>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span>广告位列表</span>
          <el-button type="success" @click="showCreateDialog">新增广告位</el-button>
        </div>
      </template>

      <el-table :data="tableData" border v-loading="loading">
        <template #empty><el-empty description="暂无数据" /></template>
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="name" label="名称" width="120" />
        <el-table-column prop="position" label="位置" width="100">
          <template #default="{ row }">
            <el-tag>{{ positionLabels[row.position] || row.position }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="impressions" label="曝光量" width="80" />
        <el-table-column prop="clicks" label="点击量" width="80" />
        <el-table-column label="点击率" width="80">
          <template #default="{ row }">{{ row.impressions > 0 ? ((row.clicks / row.impressions) * 100).toFixed(1) : 0 }}%</template>
        </el-table-column>
        <el-table-column prop="is_active" label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.is_active ? 'success' : 'danger'">{{ row.is_active ? '启用' : '禁用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="showEditDialog(row)">编辑</el-button>
            <el-button type="danger" size="small" @click="deleteItem(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="dialogVisible" :title="isCreate ? '新增广告位' : '编辑广告位'" width="600px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="名称"><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="位置">
          <el-select v-model="form.position">
            <el-option label="开屏广告" value="splash" />
            <el-option label="信息流" value="feed" />
            <el-option label="激励视频" value="rewarded" />
          </el-select>
        </el-form-item>
        <el-form-item label="内容类型">
          <el-select v-model="form.content_type">
            <el-option label="图片" value="image" />
            <el-option label="视频" value="video" />
            <el-option label="HTML" value="html" />
          </el-select>
        </el-form-item>
        <el-form-item label="跳转链接"><el-input v-model="form.target_url" /></el-form-item>
        <el-form-item label="排序"><el-input-number v-model="form.sort_order" :min="0" /></el-form-item>
        <el-form-item label="状态"><el-switch v-model="form.is_active" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveForm">保存</el-button>
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
const dialogVisible = ref(false)
const isCreate = ref(true)
const form = ref({})
const positionLabels = { splash: '开屏', feed: '信息流', rewarded: '激励视频' }

const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/ads')
    if (res.data.code === 200) tableData.value = res.data.data
  } catch (e) { console.error(e) }
  finally { loading.value = false }
}

const showCreateDialog = () => {
  isCreate.value = true
  form.value = { name: '', position: 'feed', content_type: 'image', target_url: '', sort_order: 0, is_active: true, start_time: Date.now()/1000, end_time: Date.now()/1000 + 86400*30 }
  dialogVisible.value = true
}

const showEditDialog = (row) => {
  isCreate.value = false
  form.value = { ...row }
  dialogVisible.value = true
}

const saveForm = async () => {
  try {
    await axios.post('/api/admin/ads', form.value)
    ElMessage.success('保存成功')
    dialogVisible.value = false
    loadData()
  } catch (e) { ElMessage.error('保存失败') }
}

const deleteItem = async (row) => {
  await ElMessageBox.confirm('确定删除？', '提示')
  try {
    await axios.delete(`/api/admin/ads/${row.id}`)
    ElMessage.success('删除成功')
    loadData()
  } catch (e) { ElMessage.error('删除失败') }
}

onMounted(() => loadData())
</script>

<template>
  <div>
    <h2 style="margin-bottom: 20px;">版本管理</h2>

    <el-card style="margin-bottom: 20px;">
      <template #header>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span>APP版本控制</span>
          <el-button type="success" @click="showCreateDialog">新增版本</el-button>
        </div>
      </template>

      <el-alert type="info" :closable="false" style="margin-bottom: 16px;">
        当APP版本号低于设定值时，可强制用户升级。开启"强制更新"后，用户必须升级才能使用APP。
      </el-alert>

      <el-table :data="versions" border v-loading="loading">
        <template #empty><el-empty description="暂无版本配置" /></template>
        <el-table-column prop="platform" label="平台" width="80">
          <template #default="{ row }">
            <el-tag :type="row.platform === 'ios' ? 'primary' : 'success'">
              {{ row.platform === 'ios' ? 'iOS' : 'Android' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="version_name" label="版本号" width="100" />
        <el-table-column prop="version_code" label="版本Code" width="100" />
        <el-table-column prop="force_update" label="强制更新" width="100">
          <template #default="{ row }">
            <el-tag :type="row.force_update ? 'danger' : 'info'">
              {{ row.force_update ? '是' : '否' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="update_url" label="更新链接" min-width="200" show-overflow-tooltip />
        <el-table-column prop="changelog" label="更新日志" min-width="200" show-overflow-tooltip />
        <el-table-column prop="is_active" label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.is_active ? 'success' : 'danger'">
              {{ row.is_active ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="showEditDialog(row)">编辑</el-button>
            <el-button :type="row.is_active ? 'warning' : 'success'" size="small" @click="toggleActive(row)">
              {{ row.is_active ? '禁用' : '启用' }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="dialogVisible" :title="isCreate ? '新增版本' : '编辑版本'" width="600px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="平台">
          <el-radio-group v-model="form.platform" :disabled="!isCreate">
            <el-radio value="android">Android</el-radio>
            <el-radio value="ios">iOS</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="版本名">
          <el-input v-model="form.version_name" placeholder="如 1.2.0" />
        </el-form-item>
        <el-form-item label="版本Code">
          <el-input-number v-model="form.version_code" :min="1" />
          <span style="margin-left: 8px; color: #909399; font-size: 12px;">数字越大版本越新</span>
        </el-form-item>
        <el-form-item label="强制更新">
          <el-switch v-model="form.force_update" />
          <span style="margin-left: 8px; color: #f56c6c; font-size: 12px;" v-if="form.force_update">开启后用户必须升级</span>
        </el-form-item>
        <el-form-item label="更新链接">
          <el-input v-model="form.update_url" placeholder="应用商店链接或下载地址" />
        </el-form-item>
        <el-form-item label="更新日志">
          <el-input v-model="form.changelog" type="textarea" :rows="4" placeholder="本次更新内容" />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.is_active" />
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
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

const loading = ref(false)
const versions = ref([])
const dialogVisible = ref(false)
const isCreate = ref(true)
const form = ref({})

const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/system/version')
    if (res.data.code === 200) versions.value = res.data.data
  } catch (e) { console.error(e) }
  finally { loading.value = false }
}

const showCreateDialog = () => {
  isCreate.value = true
  form.value = { platform: 'android', version_name: '1.0.0', version_code: 1, force_update: false, update_url: '', changelog: '', is_active: true }
  dialogVisible.value = true
}

const showEditDialog = (row) => {
  isCreate.value = false
  form.value = { ...row }
  dialogVisible.value = true
}

const saveForm = async () => {
  try {
    await axios.post('/api/admin/system/version', form.value)
    ElMessage.success('保存成功')
    dialogVisible.value = false
    loadData()
  } catch (e) { ElMessage.error('保存失败') }
}

const toggleActive = async (row) => {
  try {
    await axios.post('/api/admin/system/version', { ...row, is_active: !row.is_active })
    ElMessage.success('操作成功')
    loadData()
  } catch (e) { ElMessage.error('操作失败') }
}

onMounted(() => loadData())
</script>

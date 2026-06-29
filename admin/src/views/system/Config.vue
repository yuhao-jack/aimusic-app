
<template>
  <div>
    <h2 style="margin-bottom: 20px;">系统配置</h2>
    <el-card>
      <el-form :model="form" label-width="180px" style="max-width: 600px;">
        <el-form-item label="网站标题">
          <el-input v-model="form.site_title" placeholder="网站标题" />
        </el-form-item>
        <el-form-item label="用户默认每日AI配额">
          <el-input-number v-model="form.default_ai_quota" :min="0" :max="100" />
        </el-form-item>
        <el-form-item label="AI接口地址">
          <el-input v-model="form.ai_api_url" placeholder="AI生成接口地址" />
        </el-form-item>
        <el-form-item label="AI接口密钥">
          <el-input v-model="form.ai_api_key" type="password" placeholder="AI接口密钥" />
        </el-form-item>
        <el-form-item label="文件存储方式">
          <el-select v-model="form.storage_type">
            <el-option label="本地存储" value="local" />
            <el-option label="阿里云OSS" value="oss" />
            <el-option label="腾讯云COS" value="cos" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="saving" @click="saveConfig">保存配置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card title="操作日志" style="margin-top: 20px;">
      <el-table :data="logs" border max-height="400px">
        <el-table-column prop="admin_name" label="管理员" width="120" />
        <el-table-column prop="action" label="操作" width="150" />
        <el-table-column prop="ip" label="IP" width="120" />
        <el-table-column prop="created_at" label="时间" width="160" />
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

const saving = ref(false)
const form = ref({
  site_title: '',
  default_ai_quota: 10,
  ai_api_url: '',
  ai_api_key: '',
  storage_type: 'local'
})
const logs = ref([])

const loadConfig = async () => {
  try {
    const res = await axios.get('/api/admin/system/config')
    if (res.data.code === 200) {
      form.value = { ...form.value, ...res.data.data }
    }
  } catch (err) {
    console.error(err)
    ElMessage.error('加载配置失败')
  }
}

const loadLogs = async () => {
  try {
    const res = await axios.get('/api/admin/system/logs')
    if (res.data.code === 200) {
      logs.value = res.data.data.list
    }
  } catch (err) {
    console.error(err)
  }
}

const saveConfig = async () => {
  saving.value = true
  try {
    const res = await axios.post('/api/admin/system/config', form.value)
    if (res.data.code === 200) {
      ElMessage.success('保存成功')
    } else {
      ElMessage.error(res.data.message || '保存失败')
    }
  } catch (err) {
    ElMessage.error('保存失败')
  } finally {
    saving.value = false
  }
}

onMounted(() => {
  loadConfig()
  loadLogs()
})
</script>

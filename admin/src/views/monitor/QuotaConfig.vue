<template>
  <div>
    <h2 style="margin-bottom: 20px;">配额管理</h2>
    <el-card>
      <el-form :model="formData" label-width="180px" v-loading="loading">
        <!-- AI配额配置 -->
        <h3 style="margin-bottom: 16px; color: #409eff;">AI配额配置</h3>
        <el-form-item label="普通用户每日AI次数">
          <el-input-number v-model="formData.normal_daily_ai" :min="-1" :max="9999" />
          <span style="margin-left: 10px; color: #909399;">默认3次，-1表示无限制</span>
        </el-form-item>
        <el-form-item label="VIP用户每日AI次数">
          <el-input-number v-model="formData.vip_daily_ai" :min="-1" :max="9999" />
          <span style="margin-left: 10px; color: #909399;">默认20次</span>
        </el-form-item>
        <el-form-item label="SVIP用户每日AI次数">
          <el-input-number v-model="formData.svip_daily_ai" :min="-1" :max="9999" />
          <span style="margin-left: 10px; color: #909399;">默认-1（无限制）</span>
        </el-form-item>
        <el-form-item label="普通用户每次AI消耗音币">
          <el-input-number v-model="formData.normal_coin_per_ai" :min="0" :max="9999" />
          <span style="margin-left: 10px; color: #909399;">默认5音币</span>
        </el-form-item>
        <el-form-item label="VIP用户每次AI消耗音币">
          <el-input-number v-model="formData.vip_coin_per_ai" :min="0" :max="9999" />
          <span style="margin-left: 10px; color: #909399;">默认2音币</span>
        </el-form-item>
        <el-form-item label="SVIP用户每次AI消耗音币">
          <el-input-number v-model="formData.svip_coin_per_ai" :min="0" :max="9999" />
          <span style="margin-left: 10px; color: #909399;">默认0（免费）</span>
        </el-form-item>

        <el-divider />

        <!-- 限流配置 -->
        <h3 style="margin-bottom: 16px; color: #e6a23c;">限流配置</h3>
        <el-form-item label="登录限流">
          <el-input-number v-model="formData.login_rate_limit" :min="1" :max="100" />
          <span style="margin-left: 10px; color: #909399;">默认5次/分钟</span>
        </el-form-item>
        <el-form-item label="注册限流">
          <el-input-number v-model="formData.register_rate_limit" :min="1" :max="100" />
          <span style="margin-left: 10px; color: #909399;">默认3次/小时</span>
        </el-form-item>
        <el-form-item label="AI生成限流">
          <el-input-number v-model="formData.ai_rate_limit" :min="1" :max="100" />
          <span style="margin-left: 10px; color: #909399;">默认2次/分钟</span>
        </el-form-item>

        <el-divider />

        <el-form-item>
          <el-button type="primary" @click="handleSave" :loading="saving">保存配置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

const loading = ref(false)
const saving = ref(false)
const formData = ref({
  normal_daily_ai: 3,
  vip_daily_ai: 20,
  svip_daily_ai: -1,
  normal_coin_per_ai: 5,
  vip_coin_per_ai: 2,
  svip_coin_per_ai: 0,
  login_rate_limit: 5,
  register_rate_limit: 3,
  ai_rate_limit: 2
})

// 加载配置
const loadConfig = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/quota-config')
    if (res.data.code === 200) {
      formData.value = res.data.data
    }
  } catch (err) {
    console.error(err)
    ElMessage.error('加载配置失败')
  } finally {
    loading.value = false
  }
}

// 保存配置
const handleSave = async () => {
  saving.value = true
  try {
    const res = await axios.post('/api/admin/quota-config', formData.value)
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
})
</script>

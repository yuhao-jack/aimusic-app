
<template>
  <div>
    <h2 style="margin-bottom: 20px;">封禁管理</h2>
    <el-card>
      <!-- 操作栏 -->
      <div style="margin-bottom: 20px;">
        <el-button type="primary" @click="showAddDialog">新增封禁</el-button>
      </div>

      <!-- 封禁列表 -->
      <el-table :data="tableData" border v-loading="loading">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="user_id" label="用户ID" width="100" />
        <el-table-column prop="username" label="用户名" width="150" />
        <el-table-column prop="reason" label="封禁原因" width="200" show-overflow-tooltip />
        <el-table-column prop="ban_type" label="封禁类型" width="100">
          <template #default="{ row }">
            <el-tag :type="row.ban_type === 'mute' ? 'warning' : 'danger'">
              {{ row.ban_type === 'mute' ? '禁言' : '封号' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="expire_at" label="过期时间" width="180">
          <template #default="{ row }">
            <span :style="{ color: isExpired(row.expire_at) ? '#909399' : '#f56c6c' }">
              {{ row.expire_at || '永久' }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="operator" label="操作人" width="120" />
        <el-table-column prop="created_at" label="创建时间" width="180" />
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="warning" size="small" @click="handleUnban(row)">解封</el-button>
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

    <!-- 新增封禁弹窗 -->
    <el-dialog v-model="dialogVisible" title="新增封禁" width="500px">
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
        <el-form-item label="用户ID" prop="user_id">
          <el-input v-model="formData.user_id" placeholder="请输入用户ID" />
        </el-form-item>
        <el-form-item label="封禁原因" prop="reason">
          <el-input v-model="formData.reason" type="textarea" :rows="2" placeholder="请输入封禁原因" />
        </el-form-item>
        <el-form-item label="封禁类型">
          <el-radio-group v-model="formData.ban_type">
            <el-radio value="mute">禁言</el-radio>
            <el-radio value="ban">封号</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="封禁时长">
          <el-select v-model="formData.duration" placeholder="请选择时长">
            <el-option label="1小时" :value="1" />
            <el-option label="24小时" :value="24" />
            <el-option label="7天" :value="168" />
            <el-option label="30天" :value="720" />
            <el-option label="永久" :value="0" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSave">确认封禁</el-button>
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
const formData = ref({
  user_id: '',
  reason: '',
  ban_type: 'mute',
  duration: 24
})
const formRef = ref(null)
const formRules = {
  reason: [{ required: true, message: '请输入封禁原因', trigger: 'blur' }]
}

// 判断是否已过期
const isExpired = (expireAt) => {
  if (!expireAt) return false
  return new Date(expireAt) < new Date()
}

// 加载列表数据
const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/bans', {
      params: { page: currentPage.value, page_size: pageSize.value }
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
  formData.value = { user_id: '', reason: '', ban_type: 'mute', duration: 24 }
}

// 显示新增弹窗
const showAddDialog = () => {
  resetForm()
  dialogVisible.value = true
}

// 保存封禁
const handleSave = async () => {
  if (formRef.value) {
    const valid = await formRef.value.validate().catch(() => false)
    if (!valid) return
  }
  if (!formData.value.user_id) {
    ElMessage.warning('请输入用户ID')
    return
  }
  try {
    const res = await axios.post('/api/admin/bans', formData.value)
    if (res.data.code === 200) {
      ElMessage.success('封禁成功')
      dialogVisible.value = false
      loadData()
    } else {
      ElMessage.error(res.data.message || '封禁失败')
    }
  } catch (err) {
    ElMessage.error('封禁失败')
  }
}

// 解封
const handleUnban = (row) => {
  ElMessageBox.confirm(`确定解封用户 ${row.username || row.user_id} 吗？`, '提示', { type: 'warning' }).then(async () => {
    try {
      const res = await axios.post(`/api/admin/bans/${row.id}/unban`)
      if (res.data.code === 200) {
        ElMessage.success('解封成功')
        loadData()
      }
    } catch (err) {
      ElMessage.error('解封失败')
    }
  }).catch(() => {})
}

onMounted(() => {
  loadData()
})
</script>

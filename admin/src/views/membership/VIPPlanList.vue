
<template>
  <div>
    <h2 style="margin-bottom: 20px;">VIP套餐管理</h2>
    <el-card>
      <!-- 操作栏 -->
      <el-row style="margin-bottom: 20px;">
        <el-col>
          <el-button type="success" @click="showCreateDialog">新增套餐</el-button>
        </el-col>
      </el-row>

      <!-- 套餐列表 -->
      <el-table :data="tableData" border v-loading="loading">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="name" label="名称" width="150" />
        <el-table-column prop="level" label="等级" width="100">
          <template #default="{ row }">
            <el-tag :type="row.level === 'svip' ? 'danger' : 'warning'">
              {{ row.level === 'svip' ? 'SVIP' : 'VIP' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="duration_days" label="时长（天）" width="100" />
        <el-table-column prop="price" label="价格（元）" width="100" />
        <el-table-column prop="bonus_coins" label="赠送音币" width="100" />
        <el-table-column prop="is_hot" label="热门" width="80">
          <template #default="{ row }">
            <el-tag :type="row.is_hot ? 'danger' : 'info'">
              {{ row.is_hot ? '是' : '否' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'">
              {{ row.status === 1 ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="showEditDialog(row)">编辑</el-button>
            <el-button :type="row.status === 1 ? 'warning' : 'success'" size="small" @click="toggleStatus(row)">
              {{ row.status === 1 ? '禁用' : '启用' }}
            </el-button>
            <el-button type="danger" size="small" @click="deleteItem(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="isCreate ? '新增套餐' : '编辑套餐'" width="600px">
      <el-form ref="formRef" :model="form" :rules="formRules" label-width="100px">
        <el-form-item label="名称" prop="name">
          <el-input v-model="form.name" placeholder="请输入套餐名称" />
        </el-form-item>
        <el-form-item label="等级">
          <el-select v-model="form.level">
            <el-option label="VIP" value="vip" />
            <el-option label="SVIP" value="svip" />
          </el-select>
        </el-form-item>
        <el-form-item label="时长（天）">
          <el-input-number v-model="form.duration_days" :min="1" />
        </el-form-item>
        <el-form-item label="价格（元）">
          <el-input-number v-model="form.price" :min="0" :precision="2" />
        </el-form-item>
        <el-form-item label="赠送音币">
          <el-input-number v-model="form.bonus_coins" :min="0" />
        </el-form-item>
        <el-form-item label="热门">
          <el-switch v-model="form.is_hot" />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" />
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
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

const loading = ref(false)
const tableData = ref([])
const dialogVisible = ref(false)
const isCreate = ref(true)
const form = ref({})
const formRef = ref(null)
const formRules = {
  name: [{ required: true, message: '请输入套餐名称', trigger: 'blur' }]
}

// 加载数据
const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/vip-plans')
    if (res.data.code === 200) {
      tableData.value = res.data.data.list || res.data.data
    }
  } catch (err) {
    console.error(err)
    ElMessage.error('加载数据失败')
  } finally {
    loading.value = false
  }
}

// 显示新增弹窗
const showCreateDialog = () => {
  form.value = { name: '', level: 'vip', duration_days: 30, price: 0, bonus_coins: 0, is_hot: false, status: 1 }
  isCreate.value = true
  dialogVisible.value = true
}

// 显示编辑弹窗
const showEditDialog = (row) => {
  form.value = { ...row }
  isCreate.value = false
  dialogVisible.value = true
}

// 保存表单
const saveForm = async () => {
  if (formRef.value) {
    const valid = await formRef.value.validate().catch(() => false)
    if (!valid) return
  }
  try {
    let res
    if (isCreate.value) {
      res = await axios.post('/api/admin/vip-plans', form.value)
    } else {
      res = await axios.put(`/api/admin/vip-plans/${form.value.id}`, form.value)
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

// 切换状态
const toggleStatus = async (row) => {
  try {
    const newStatus = row.status === 1 ? 0 : 1
    const res = await axios.put(`/api/admin/vip-plans/${row.id}`, { ...row, status: newStatus })
    if (res.data.code === 200) {
      ElMessage.success('操作成功')
      loadData()
    } else {
      ElMessage.error(res.data.message || '操作失败')
    }
  } catch (err) {
    ElMessage.error('操作失败')
  }
}

// 删除
const deleteItem = async (row) => {
  try {
    await ElMessageBox.confirm('确认删除该套餐吗？删除后无法恢复', '提示')
    const res = await axios.delete(`/api/admin/vip-plans/${row.id}`)
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

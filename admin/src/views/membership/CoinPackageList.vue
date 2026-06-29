<template>
  <div>
    <h2 style="margin-bottom: 20px;">音币充值包管理</h2>
    <el-card>
      <el-row style="margin-bottom: 20px;">
        <el-col>
          <el-button type="success" @click="showCreateDialog">新增充值包</el-button>
        </el-col>
      </el-row>

      <el-table :data="tableData" border v-loading="loading">
        <template #empty><el-empty description="暂无数据" /></template>
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="name" label="名称" width="180" />
        <el-table-column prop="coins" label="音币数量" width="100" />
        <el-table-column label="价格（元）" width="100">
          <template #default="{ row }">{{ (row.price / 100).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column prop="bonus" label="赠送音币" width="100" />
        <el-table-column prop="sort_order" label="排序" width="80" />
        <el-table-column prop="is_active" label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.is_active ? 'success' : 'danger'">
              {{ row.is_active ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="showEditDialog(row)">编辑</el-button>
            <el-button :type="row.is_active ? 'warning' : 'success'" size="small" @click="toggleStatus(row)">
              {{ row.is_active ? '禁用' : '启用' }}
            </el-button>
            <el-button type="danger" size="small" @click="deleteItem(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="dialogVisible" :title="isCreate ? '新增充值包' : '编辑充值包'" width="600px">
      <el-form ref="formRef" :model="form" :rules="formRules" label-width="100px">
        <el-form-item label="名称" prop="name">
          <el-input v-model="form.name" placeholder="请输入充值包名称" />
        </el-form-item>
        <el-form-item label="音币数量">
          <el-input-number v-model="form.coins" :min="1" />
        </el-form-item>
        <el-form-item label="价格（元）">
          <el-input-number v-model="form.priceYuan" :min="0" :precision="2" />
        </el-form-item>
        <el-form-item label="赠送音币">
          <el-input-number v-model="form.bonus" :min="0" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sort_order" :min="0" />
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
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

const loading = ref(false)
const tableData = ref([])
const dialogVisible = ref(false)
const isCreate = ref(true)
const formRef = ref(null)
const form = ref({})

const formRules = {
  name: [{ required: true, message: '请输入名称', trigger: 'blur' }]
}

const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/coin-packages')
    if (res.data.code === 200) tableData.value = res.data.data
  } catch (e) {
    ElMessage.error('加载失败')
  } finally { loading.value = false }
}

const showCreateDialog = () => {
  isCreate.value = true
  form.value = { name: '', coins: 100, priceYuan: 10, bonus: 0, sort_order: 0, is_active: true }
  dialogVisible.value = true
}

const showEditDialog = (row) => {
  isCreate.value = false
  form.value = { ...row, priceYuan: row.price / 100 }
  dialogVisible.value = true
}

const saveForm = async () => {
  const data = { ...form.value, price: Math.round(form.value.priceYuan * 100) }
  delete data.priceYuan
  try {
    if (isCreate.value) {
      await axios.post('/api/admin/coin-packages', data)
      ElMessage.success('创建成功')
    } else {
      await axios.put(`/api/admin/coin-packages/${data.id}`, data)
      ElMessage.success('更新成功')
    }
    dialogVisible.value = false
    loadData()
  } catch (e) { ElMessage.error('操作失败') }
}

const toggleStatus = async (row) => {
  try {
    await axios.put(`/api/admin/coin-packages/${row.id}`, { is_active: !row.is_active })
    ElMessage.success('操作成功')
    loadData()
  } catch (e) { ElMessage.error('操作失败') }
}

const deleteItem = async (row) => {
  await ElMessageBox.confirm('确定删除？', '提示')
  try {
    await axios.delete(`/api/admin/coin-packages/${row.id}`)
    ElMessage.success('删除成功')
    loadData()
  } catch (e) { ElMessage.error('删除失败') }
}

onMounted(() => loadData())
</script>

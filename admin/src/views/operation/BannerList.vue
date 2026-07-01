
<template>
  <div>
    <h2 style="margin-bottom: 20px;">Banner管理</h2>
    <el-card>
      <!-- 操作栏 -->
      <div style="margin-bottom: 20px;">
        <el-button type="primary" @click="showAddDialog">新增Banner</el-button>
      </div>

      <!-- Banner列表 -->
      <el-table :data="tableData" border v-loading="loading">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="title" label="标题" width="180" />
        <el-table-column label="图片" width="150">
          <template #default="{ row }">
            <el-image
              v-if="row.image"
              :src="row.image"
              :preview-src-list="[row.image]"
              style="width: 100px; height: 50px;"
              fit="cover"
            />
            <span v-else>无图片</span>
          </template>
        </el-table-column>
        <el-table-column prop="link" label="跳转链接" width="200" show-overflow-tooltip />
        <el-table-column prop="position" label="位置" width="120">
          <template #default="{ row }">
            <el-tag>{{ positionMap[row.position] || row.position }}</el-tag>
          </template>
        </el-table-column>
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
    <el-dialog v-model="dialogVisible" :title="isEdit ? '编辑Banner' : '新增Banner'" width="550px">
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
        <el-form-item label="标题" prop="title">
          <el-input v-model="formData.title" placeholder="请输入标题" />
        </el-form-item>
        <el-form-item label="图片URL" prop="image">
          <el-input v-model="formData.image" placeholder="请输入图片地址" />
        </el-form-item>
        <el-form-item label="跳转链接">
          <el-input v-model="formData.link" placeholder="请输入跳转链接" />
        </el-form-item>
        <el-form-item label="链接类型">
          <el-select v-model="formData.link_type" placeholder="请选择类型">
            <el-option label="歌曲" :value="1" />
            <el-option label="歌单" :value="2" />
            <el-option label="活动" :value="3" />
            <el-option label="外链" :value="4" />
          </el-select>
        </el-form-item>
        <el-form-item label="展示位置">
          <el-select v-model="formData.position" placeholder="请选择位置">
            <el-option label="首页" value="home" />
            <el-option label="播放页" value="player" />
            <el-option label="创作页" value="create" />
          </el-select>
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
const formRef = ref(null)
const formData = ref({})

const positionMap = {
  home: '首页',
  player: '播放页',
  create: '创作页'
}

const formRules = {
  title: [{ required: true, message: '请输入标题', trigger: 'blur' }],
  image: [{ required: true, message: '请输入图片URL', trigger: 'blur' }]
}

const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/banners', {
      params: { page: currentPage.value, page_size: pageSize.value }
    })
    if (res.data.code === 200) {
      tableData.value = res.data.data.list || res.data.data
      total.value = res.data.data.total || tableData.value.length
    }
  } catch (e) {
    ElMessage.error('加载失败')
  } finally {
    loading.value = false
  }
}

const showAddDialog = () => {
  isEdit.value = false
  formData.value = {
    title: '', image: '', link: '', link_type: 4,
    position: 'home', sort_order: 0, is_active: true
  }
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
      await axios.put(`/api/admin/banners/${formData.value.id}`, formData.value)
    } else {
      await axios.post('/api/admin/banners', formData.value)
    }
    ElMessage.success(isEdit.value ? '更新成功' : '创建成功')
    dialogVisible.value = false
    loadData()
  } catch (e) {
    ElMessage.error('操作失败')
  }
}

const handleDelete = async (row) => {
  await ElMessageBox.confirm('确定删除该Banner？', '提示')
  try {
    await axios.delete(`/api/admin/banners/${row.id}`)
    ElMessage.success('删除成功')
    loadData()
  } catch (e) {
    ElMessage.error('删除失败')
  }
}

onMounted(() => loadData())
</script>

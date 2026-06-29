
<template>
  <div>
    <h2 style="margin-bottom: 20px;">会员管理</h2>
    <el-card>
      <!-- 搜索区域 -->
      <el-row :gutter="10" style="margin-bottom: 20px;">
        <el-col :span="8">
          <el-input v-model="searchKeyword" placeholder="搜索昵称/手机号" clearable />
        </el-col>
        <el-col :span="4">
          <el-select v-model="filterLevel" placeholder="会员等级" clearable>
            <el-option label="全部" value="" />
            <el-option label="普通" value="normal" />
            <el-option label="VIP" value="vip" />
            <el-option label="SVIP" value="svip" />
          </el-select>
        </el-col>
        <el-col :span="4">
          <el-button type="primary" @click="loadData">搜索</el-button>
          <el-button @click="resetSearch">重置</el-button>
        </el-col>
      </el-row>

      <!-- 会员列表 -->
      <el-table :data="tableData" border v-loading="loading">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="nickname" label="昵称" width="150" />
        <el-table-column prop="phone" label="手机号" width="140" />
        <el-table-column prop="vip_level" label="会员等级" width="100">
          <template #default="{ row }">
            <el-tag :type="getVipLevelType(row.vip_level)">
              {{ getVipLevelLabel(row.vip_level) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="vip_expire_at" label="到期时间" width="180" />
        <el-table-column prop="coin_balance" label="音币余额" width="100" />
        <el-table-column prop="created_at" label="注册时间" width="180" />
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="showEditDialog(row)">编辑</el-button>
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

    <!-- 编辑弹窗 -->
    <el-dialog v-model="dialogVisible" title="编辑会员" width="500px">
      <el-form :model="editForm" label-width="100px">
        <el-form-item label="昵称">
          <el-input v-model="editForm.nickname" disabled />
        </el-form-item>
        <el-form-item label="会员等级">
          <el-select v-model="editForm.vip_level">
            <el-option label="普通" value="normal" />
            <el-option label="VIP" value="vip" />
            <el-option label="SVIP" value="svip" />
          </el-select>
        </el-form-item>
        <el-form-item label="音币余额">
          <el-input-number v-model="editForm.coin_balance" :min="0" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveEdit">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

const loading = ref(false)
const searchKeyword = ref('')
const filterLevel = ref('')
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const dialogVisible = ref(false)
const editForm = ref({})

// 获取会员等级标签类型
const getVipLevelType = (level) => {
  const map = { normal: 'info', vip: 'warning', svip: 'danger' }
  return map[level] || 'info'
}

// 获取会员等级显示文本
const getVipLevelLabel = (level) => {
  const map = { normal: '普通', vip: 'VIP', svip: 'SVIP' }
  return map[level] || level
}

// 加载数据
const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/members', {
      params: {
        page: currentPage.value,
        page_size: pageSize.value,
        keyword: searchKeyword.value,
        vip_level: filterLevel.value
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

// 重置搜索
const resetSearch = () => {
  searchKeyword.value = ''
  filterLevel.value = ''
  currentPage.value = 1
  loadData()
}

// 显示编辑弹窗
const showEditDialog = (row) => {
  editForm.value = { ...row }
  dialogVisible.value = true
}

// 保存编辑
const saveEdit = async () => {
  try {
    const res = await axios.put(`/api/admin/members/${editForm.value.id}`, {
      vip_level: editForm.value.vip_level,
      coin_balance: editForm.value.coin_balance
    })
    if (res.data.code === 200) {
      ElMessage.success('保存成功')
      dialogVisible.value = false
      loadData()
    } else {
      ElMessage.error(res.data.message || '保存失败')
    }
  } catch (err) {
    ElMessage.error('保存失败')
  }
}

onMounted(() => {
  loadData()
})
</script>

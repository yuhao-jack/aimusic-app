
<template>
  <div>
    <h2 style="margin-bottom: 20px;">举报管理</h2>
    <el-card>
      <!-- 筛选区域 -->
      <el-row :gutter="10" style="margin-bottom: 20px;">
        <el-col :span="6">
          <el-select v-model="filterStatus" placeholder="筛选状态" clearable>
            <el-option label="待处理" value="pending" />
            <el-option label="已处理" value="resolved" />
            <el-option label="已驳回" value="rejected" />
          </el-select>
        </el-col>
        <el-col :span="6">
          <el-select v-model="filterTargetType" placeholder="目标类型" clearable>
            <el-option label="歌曲" value="song" />
            <el-option label="动态" value="post" />
            <el-option label="评论" value="comment" />
            <el-option label="用户" value="user" />
          </el-select>
        </el-col>
        <el-col :span="4">
          <el-button type="primary" @click="loadData">搜索</el-button>
          <el-button @click="resetFilter">重置</el-button>
        </el-col>
      </el-row>

      <!-- 举报列表 -->
      <el-table :data="tableData" border v-loading="loading">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="reporter_id" label="举报者ID" width="100" />
        <el-table-column prop="target_type" label="目标类型" width="100">
          <template #default="{ row }">
            <el-tag :type="targetTypeTag[row.target_type]">
              {{ targetTypeMap[row.target_type] || row.target_type }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="target_id" label="目标ID" width="100" />
        <el-table-column prop="reason" label="举报原因" width="150" show-overflow-tooltip />
        <el-table-column prop="detail" label="详情" width="200" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="statusTag[row.status]">
              {{ statusMap[row.status] || row.status }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="handler_id" label="处理人ID" width="100" />
        <el-table-column prop="handle_remark" label="处理备注" width="150" show-overflow-tooltip />
        <el-table-column prop="created_at" label="举报时间" width="180" />
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button
              v-if="row.status === 'pending'"
              type="primary"
              size="small"
              @click="showHandleDialog(row)"
            >处理</el-button>
            <span v-else style="color: #909399; font-size: 12px;">已处理</span>
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

    <!-- 处理弹窗 -->
    <el-dialog v-model="dialogVisible" title="处理举报" width="500px">
      <el-form ref="handleFormRef" :model="handleForm" :rules="handleRules" label-width="100px">
        <el-form-item label="举报信息">
          <span>【{{ targetTypeMap[currentReport.target_type] }}】{{ currentReport.reason }}</span>
        </el-form-item>
        <el-form-item label="处理结果">
          <el-radio-group v-model="handleForm.result">
            <el-radio value="resolved">通过（确认违规）</el-radio>
            <el-radio value="rejected">驳回（不违规）</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="处理备注" prop="remark">
          <el-input v-model="handleForm.remark" type="textarea" :rows="3" placeholder="请输入处理备注" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitHandle">提交</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

// 状态映射
const statusMap = { pending: '待处理', resolved: '已处理', rejected: '已驳回' }
const statusTag = { pending: 'warning', resolved: 'success', rejected: 'danger' }
// 目标类型映射
const targetTypeMap = { song: '歌曲', post: '动态', comment: '评论', user: '用户' }
const targetTypeTag = { song: '', post: 'success', comment: 'warning', user: 'danger' }

const loading = ref(false)
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const filterStatus = ref('')
const filterTargetType = ref('')
const dialogVisible = ref(false)
const currentReport = ref({})
const handleForm = ref({ result: 'resolved', remark: '' })
const handleFormRef = ref(null)
const handleRules = {
  remark: [{ required: true, message: '请输入处理备注', trigger: 'blur' }]
}

// 加载列表数据
const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/reports', {
      params: {
        page: currentPage.value,
        page_size: pageSize.value,
        status: filterStatus.value,
        target_type: filterTargetType.value
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

// 重置筛选
const resetFilter = () => {
  filterStatus.value = ''
  filterTargetType.value = ''
  currentPage.value = 1
  loadData()
}

// 显示处理弹窗
const showHandleDialog = (row) => {
  currentReport.value = row
  handleForm.value = { result: 'resolved', remark: '' }
  dialogVisible.value = true
}

// 提交处理
const submitHandle = async () => {
  if (handleFormRef.value) {
    const valid = await handleFormRef.value.validate().catch(() => false)
    if (!valid) return
  }
  try {
    const res = await axios.post(`/api/admin/reports/${currentReport.value.id}/handle`, {
      status: handleForm.value.result,
      remark: handleForm.value.remark
    })
    if (res.data.code === 200) {
      ElMessage.success('处理成功')
      dialogVisible.value = false
      loadData()
    } else {
      ElMessage.error(res.data.message || '处理失败')
    }
  } catch (err) {
    ElMessage.error('处理失败')
  }
}

onMounted(() => {
  loadData()
})
</script>


<template>
  <div>
    <h2 style="margin-bottom: 20px;">内容审核</h2>
    <el-card>
      <!-- 筛选 -->
      <el-row :gutter="10" style="margin-bottom: 20px;">
        <el-col :span="6">
          <el-select v-model="contentType" placeholder="内容类型">
            <el-option label="全部" value="" />
            <el-option label="用户动态" value="post" />
            <el-option label="评论" value="comment" />
          </el-select>
        </el-col>
        <el-col :span="6">
          <el-select v-model="status" placeholder="审核状态">
            <el-option label="待审核" value="0" />
            <el-option label="已通过" value="1" />
            <el-option label="已拒绝" value="2" />
          </el-select>
        </el-col>
        <el-col :span="4">
          <el-button type="primary" @click="loadData">查询</el-button>
          <el-button @click="resetSearch">重置</el-button>
        </el-col>
      </el-row>

      <el-table :data="tableData" border v-loading="loading">
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="content_type" label="类型" width="100">
          <template #default="{ row }">
            {{ row.content_type === 'post' ? '用户动态' : '评论' }}
          </template>
        </el-table-column>
        <el-table-column prop="user_nickname" label="发布用户" width="120" />
        <el-table-column prop="content" label="内容" min-width="200" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 0 ? 'warning' : row.status === 1 ? 'success' : 'danger'">
              {{ row.status === 0 ? '待审核' : row.status === 1 ? '通过' : '拒绝' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="提交时间" width="160" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button v-if="row.status === 0" type="success" size="small" @click="auditPass(row)">通过</el-button>
            <el-button v-if="row.status === 0" type="danger" size="small" @click="auditReject(row)">拒绝</el-button>
            <el-button type="primary" size="small" @click="showDetail(row)">查看详情</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div style="margin-top: 20px; text-align: right;">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50]"
          :total="total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="loadData"
          @current-change="loadData"
        />
      </div>
    </el-card>

    <!-- 详情弹窗 -->
    <el-dialog v-model="dialogVisible" title="内容详情" width="600px">
      <div v-if="currentItem">
        <p><strong>类型：</strong>{{ currentItem.content_type === 'post' ? '用户动态' : '评论' }}</p>
        <p><strong>发布用户：</strong>{{ currentItem.user_nickname }} (ID: {{ currentItem.user_id }})</p>
        <p><strong>内容：</strong></p>
        <p>{{ currentItem.content }}</p>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

const loading = ref(false)
const contentType = ref('')
const status = ref(0)
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const dialogVisible = ref(false)
const currentItem = ref(null)

const loadData = async () => {
  loading.value = true
  try {
    const params = {
      page: currentPage.value,
      page_size: pageSize.value
    }
    if (contentType.value) {
      params.content_type = contentType.value
    }
    if (status.value !== '') {
      params.status = status.value
    }
    const res = await axios.get('/api/admin/audit', { params })
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

const resetSearch = () => {
  contentType.value = ''
  status.value = 0
  currentPage.value = 1
  loadData()
}

const showDetail = (row) => {
  currentItem.value = row
  dialogVisible.value = true
}

const auditPass = async (row) => {
  try {
    const res = await axios.post(`/api/admin/audit/${row.id}/pass`, {
      content_type: row.content_type
    })
    if (res.data.code === 200) {
      ElMessage.success('审核通过')
      loadData()
    } else {
      ElMessage.error(res.data.message || '操作失败')
    }
  } catch (err) {
    ElMessage.error('操作失败')
  }
}

const auditReject = async (row) => {
  try {
    const res = await axios.post(`/api/admin/audit/${row.id}/reject`, {
      content_type: row.content_type
    })
    if (res.data.code === 200) {
      ElMessage.success('已拒绝')
      loadData()
    } else {
      ElMessage.error(res.data.message || '操作失败')
    }
  } catch (err) {
    ElMessage.error('操作失败')
  }
}

onMounted(() => {
  loadData()
})
</script>

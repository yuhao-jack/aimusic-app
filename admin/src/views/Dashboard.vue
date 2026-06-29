
<template>
  <div>
    <h2 style="margin-bottom: 20px;">仪表盘</h2>
    <el-row :gutter="20">
      <el-col :span="6" v-for="item in statsCards" :key="item.key">
        <el-card>
          <div class="stat-card">
            <div class="stat-value">{{ item.value }}</div>
            <div class="stat-label">{{ item.label }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" style="margin-top: 20px;">
      <el-col :span="24">
        <el-card>
          <h3>最近数据统计</h3>
          <p>数据统计图表区域，后续可扩展ECharts展示趋势</p>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

const statsCards = ref([
  { key: 'total_users', label: '总用户数', value: 0 },
  { key: 'total_songs', label: '总歌曲数', value: 0 },
  { key: 'total_ai_creations', label: 'AI创作总数', value: 0 },
  { key: 'total_posts', label: '动态总数', value: 0 }
])

const loadStats = async () => {
  try {
    const res = await axios.get('/api/admin/dashboard/stats')
    if (res.data.code === 200) {
      statsCards.value[0].value = res.data.data.total_users
      statsCards.value[1].value = res.data.data.total_songs
      statsCards.value[2].value = res.data.data.total_ai_creations
      statsCards.value[3].value = res.data.data.total_posts
    }
  } catch (err) {
    console.error('加载统计数据失败', err)
  }
}

onMounted(() => {
  loadStats()
})
</script>

<style scoped>
.stat-card {
  text-align: center;
  padding: 10px 0;
}

.stat-value {
  font-size: 32px;
  font-weight: bold;
  color: #409eff;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 14px;
  color: #666;
}
</style>

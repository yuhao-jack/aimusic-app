
<template>
  <div>
    <h2 style="margin-bottom: 20px;">内容运营</h2>

    <!-- 顶部指标 -->
    <el-row :gutter="20" style="margin-bottom: 24px;">
      <el-col :span="6" v-for="card in metricCards" :key="card.title">
        <el-card shadow="hover">
          <div class="metric-card">
            <div class="metric-card__title">{{ card.title }}</div>
            <div class="metric-card__value">{{ card.value }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 热门歌曲排行 -->
    <el-card style="margin-bottom: 24px;">
      <template #header>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span>热门歌曲排行</span>
          <el-radio-group v-model="songRankType" size="small">
            <el-radio-button value="plays">播放量</el-radio-button>
            <el-radio-button value="likes">点赞量</el-radio-button>
            <el-radio-button value="comments">评论量</el-radio-button>
          </el-radio-group>
        </div>
      </template>
      <el-table :data="songRank" border>
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column type="index" label="排名" width="80" />
        <el-table-column prop="title" label="歌曲名称" min-width="200" show-overflow-tooltip />
        <el-table-column prop="artist" label="歌手" width="120" />
        <el-table-column prop="plays" label="播放量" width="120">
          <template #default="{ row }">
            {{ row.plays.toLocaleString() }}
          </template>
        </el-table-column>
        <el-table-column prop="likes" label="点赞量" width="120">
          <template #default="{ row }">
            {{ row.likes.toLocaleString() }}
          </template>
        </el-table-column>
        <el-table-column prop="comments" label="评论量" width="120" />
        <el-table-column label="趋势" width="100">
          <template #default="{ row }">
            <span :class="row.trendDir === 'up' ? 'trend-up' : 'trend-down'">
              {{ row.trendDir === 'up' ? '↑' : '↓' }} {{ row.trend }}
            </span>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 热门话题排行 -->
    <el-card style="margin-bottom: 24px;">
      <template #header>热门话题排行</template>
      <el-table :data="topicRank" border>
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column type="index" label="排名" width="80" />
        <el-table-column prop="name" label="话题名称" min-width="200" />
        <el-table-column prop="post_count" label="动态数" width="120" />
        <el-table-column prop="view_count" label="浏览量" width="120">
          <template #default="{ row }">
            {{ row.view_count.toLocaleString() }}
          </template>
        </el-table-column>
        <el-table-column prop="participant_count" label="参与人数" width="120" />
        <el-table-column label="热度趋势" width="140">
          <template #default="{ row }">
            <el-progress :percentage="row.heat" :color="getHeatColor(row.heat)" />
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 优质内容推荐 -->
    <el-card style="margin-bottom: 24px;">
      <template #header>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span>优质内容推荐</span>
          <el-button type="primary" size="small" @click="showRecommendDialog">添加推荐</el-button>
        </div>
      </template>
      <el-table :data="recommendList" border>
        <template #empty>
          <el-empty description="暂无数据" />
        </template>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="title" label="内容标题" min-width="200" show-overflow-tooltip />
        <el-table-column prop="type" label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="row.type === 'song' ? '' : 'warning'">
              {{ row.type === 'song' ? '歌曲' : '动态' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="author" label="作者" width="120" />
        <el-table-column label="推荐状态" width="120">
          <template #default="{ row }">
            <el-tag :type="row.is_top ? 'danger' : row.is_recommend ? 'success' : 'info'">
              {{ row.is_top ? '置顶' : row.is_recommend ? '推荐中' : '普通' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180" />
        <el-table-column label="操作" width="240" fixed="right">
          <template #default="{ row }">
            <el-button size="small" :type="row.is_top ? 'info' : 'danger'" @click="toggleTop(row)">
              {{ row.is_top ? '取消置顶' : '置顶' }}
            </el-button>
            <el-button size="small" :type="row.is_recommend ? 'info' : 'success'" @click="toggleRecommend(row)">
              {{ row.is_recommend ? '取消推荐' : '推荐到首页' }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 内容审核效率统计 -->
    <el-card>
      <template #header>内容审核效率统计</template>
      <el-row :gutter="20">
        <el-col :span="6">
          <div class="audit-stat">
            <div class="audit-stat__label">今日待审核</div>
            <div class="audit-stat__value warning">{{ auditStats.pending }}</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="audit-stat">
            <div class="audit-stat__label">今日已审核</div>
            <div class="audit-stat__value success">{{ auditStats.reviewed }}</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="audit-stat">
            <div class="audit-stat__label">平均审核时长</div>
            <div class="audit-stat__value primary">{{ auditStats.avg_time }}分钟</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="audit-stat">
            <div class="audit-stat__label">审核通过率</div>
            <div class="audit-stat__value" :style="{ color: auditStats.pass_rate >= 80 ? '#67c23a' : '#e6a23c' }">
              {{ auditStats.pass_rate }}%
            </div>
          </div>
        </el-col>
      </el-row>
      <div style="margin-top: 20px;">
        <div class="chart-container">
          <div class="bar-chart">
            <div v-for="(item, index) in auditTrend" :key="index" class="bar-chart__item">
              <div class="bar-chart__bar-wrapper">
                <div
                  class="bar-chart__bar"
                  :style="{ height: getAuditBarHeight(item.value) + '%', backgroundColor: '#409eff' }"
                >
                  <span class="bar-chart__tooltip">{{ item.date }}: {{ item.value }}条</span>
                </div>
              </div>
              <div class="bar-chart__label">{{ item.date }}</div>
            </div>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 推荐弹窗 -->
    <el-dialog v-model="recommendDialogVisible" title="添加推荐内容" width="500px">
      <el-form :model="recommendForm" label-width="100px">
        <el-form-item label="内容类型">
          <el-radio-group v-model="recommendForm.type">
            <el-radio value="song">歌曲</el-radio>
            <el-radio value="post">动态</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="内容ID">
          <el-input v-model="recommendForm.content_id" placeholder="请输入歌曲/动态ID" />
        </el-form-item>
        <el-form-item label="推荐类型">
          <el-checkbox v-model="recommendForm.is_recommend">推荐到首页</el-checkbox>
          <el-checkbox v-model="recommendForm.is_top">置顶</el-checkbox>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="recommendDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleAddRecommend">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

// 顶部指标
const metricCards = ref([
  { title: '今日新增歌曲', value: '128' },
  { title: '今日新增动态', value: '456' },
  { title: '待审核内容', value: '89' },
  { title: '今日推荐内容', value: '12' }
])

// 歌曲排行类型
const songRankType = ref('plays')

// 热门歌曲排行（模拟数据）
const songRank = ref([
  { title: '星辰大海', artist: '黄霄雲', plays: 1256789, likes: 89234, comments: 5678, trend: '15%', trendDir: 'up' },
  { title: '孤勇者', artist: '陈奕迅', plays: 987654, likes: 76543, comments: 4321, trend: '8%', trendDir: 'up' },
  { title: '起风了', artist: '买辣椒也用券', plays: 876543, likes: 65432, comments: 3456, trend: '5%', trendDir: 'down' },
  { title: '光年之外', artist: '邓紫棋', plays: 765432, likes: 54321, comments: 2890, trend: '12%', trendDir: 'up' },
  { title: '稻香', artist: '周杰伦', plays: 654321, likes: 43210, comments: 2345, trend: '3%', trendDir: 'down' }
])

// 热门话题排行（模拟数据）
const topicRank = ref([
  { name: '#AI音乐创作大赛', post_count: 2345, view_count: 567890, participant_count: 1234, heat: 95 },
  { name: '#每日一歌', post_count: 1890, view_count: 456789, participant_count: 987, heat: 82 },
  { name: '#翻唱挑战', post_count: 1567, view_count: 345678, participant_count: 765, heat: 73 },
  { name: '#音乐心情', post_count: 1234, view_count: 234567, participant_count: 543, heat: 65 },
  { name: '#新歌推荐', post_count: 987, view_count: 123456, participant_count: 432, heat: 48 }
])

const getHeatColor = (heat) => {
  if (heat >= 80) return '#f56c6c'
  if (heat >= 60) return '#e6a23c'
  return '#409eff'
}

// 优质内容推荐（模拟数据）
const recommendList = ref([
  { id: 1, title: 'AI生成的古风歌曲《长安夜》', type: 'song', author: '音乐达人小王', is_top: true, is_recommend: true, created_at: '2024-01-15 10:30:00' },
  { id: 2, title: '用AI创作的第一首说唱', type: 'post', author: 'Rapper小李', is_top: false, is_recommend: true, created_at: '2024-01-15 09:20:00' },
  { id: 3, title: 'AI帮我写的民谣《故乡》', type: 'song', author: '民谣歌手', is_top: false, is_recommend: false, created_at: '2024-01-14 18:45:00' }
])

// 审核统计
const auditStats = ref({
  pending: 89,
  reviewed: 234,
  avg_time: 15,
  pass_rate: 92.5
})

// 审核趋势（模拟数据）
const auditTrend = ref([])
for (let i = 6; i >= 0; i--) {
  const date = new Date()
  date.setDate(date.getDate() - i)
  auditTrend.value.push({
    date: `${date.getMonth() + 1}/${date.getDate()}`,
    value: Math.floor(150 + Math.random() * 150)
  })
}

const getAuditBarHeight = (value) => {
  const max = Math.max(...auditTrend.value.map(d => d.value), 1)
  return (value / max) * 100
}

// 推荐弹窗
const recommendDialogVisible = ref(false)
const recommendForm = ref({
  type: 'song',
  content_id: '',
  is_recommend: true,
  is_top: false
})

const showRecommendDialog = () => {
  recommendForm.value = { type: 'song', content_id: '', is_recommend: true, is_top: false }
  recommendDialogVisible.value = true
}

const handleAddRecommend = () => {
  ElMessage.success('添加推荐成功')
  recommendDialogVisible.value = false
}

const toggleTop = (row) => {
  row.is_top = !row.is_top
  ElMessage.success(row.is_top ? '已置顶' : '已取消置顶')
}

const toggleRecommend = (row) => {
  row.is_recommend = !row.is_recommend
  ElMessage.success(row.is_recommend ? '已推荐到首页' : '已取消推荐')
}

onMounted(() => {
  // 后续对接真实API
})
</script>

<style scoped>
.metric-card {
  text-align: center;
  padding: 10px 0;
}
.metric-card__title {
  font-size: 14px;
  color: #909399;
  margin-bottom: 10px;
}
.metric-card__value {
  font-size: 32px;
  font-weight: bold;
  color: #303133;
}

.trend-up {
  color: #67c23a;
}
.trend-down {
  color: #f56c6c;
}

/* 审核统计 */
.audit-stat {
  text-align: center;
  padding: 20px;
  border: 1px solid #ebeef5;
  border-radius: 8px;
}
.audit-stat__label {
  font-size: 14px;
  color: #909399;
  margin-bottom: 10px;
}
.audit-stat__value {
  font-size: 28px;
  font-weight: bold;
}
.audit-stat__value.warning {
  color: #e6a23c;
}
.audit-stat__value.success {
  color: #67c23a;
}
.audit-stat__value.primary {
  color: #409eff;
}

/* 柱状图 */
.chart-container {
  height: 200px;
  padding: 20px 0;
}
.bar-chart {
  display: flex;
  align-items: flex-end;
  height: 100%;
  gap: 4px;
}
.bar-chart__item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  height: 100%;
}
.bar-chart__bar-wrapper {
  flex: 1;
  width: 100%;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}
.bar-chart__bar {
  width: 60%;
  min-width: 20px;
  max-width: 40px;
  border-radius: 3px 3px 0 0;
  position: relative;
  transition: height 0.3s;
  cursor: pointer;
}
.bar-chart__bar:hover .bar-chart__tooltip {
  display: block;
}
.bar-chart__tooltip {
  display: none;
  position: absolute;
  top: -28px;
  left: 50%;
  transform: translateX(-50%);
  background: #303133;
  color: #fff;
  font-size: 12px;
  padding: 2px 6px;
  border-radius: 4px;
  white-space: nowrap;
}
.bar-chart__label {
  font-size: 12px;
  color: #909399;
  margin-top: 8px;
}
</style>

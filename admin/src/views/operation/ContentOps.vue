<template>
  <div>
    <h2 style="margin-bottom: 20px;">内容运营</h2>

    <!-- 顶部指标 -->
    <el-row :gutter="20" style="margin-bottom: 24px;">
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="metric-card">
            <div class="metric-card__title">今日新增歌曲</div>
            <div class="metric-card__value">{{ metrics.today_songs || 0 }}</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="metric-card">
            <div class="metric-card__title">今日新增动态</div>
            <div class="metric-card__value">{{ metrics.today_posts || 0 }}</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="metric-card">
            <div class="metric-card__title">待审核内容</div>
            <div class="metric-card__value" style="color: #e6a23c;">{{ metrics.pending_audit || 0 }}</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="metric-card">
            <div class="metric-card__title">总歌曲数</div>
            <div class="metric-card__value">{{ metrics.total_songs || 0 }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 热门歌曲排行 -->
    <el-card style="margin-bottom: 24px;">
      <template #header><span>热门歌曲排行 Top10</span></template>
      <el-table :data="hotSongs" border v-loading="loading">
        <template #empty><el-empty description="暂无数据" /></template>
        <el-table-column type="index" label="排名" width="80" />
        <el-table-column prop="title" label="歌曲名称" min-width="200" show-overflow-tooltip />
        <el-table-column prop="artist" label="歌手" width="120" />
        <el-table-column prop="plays" label="播放量" width="120" sortable>
          <template #default="{ row }">{{ row.plays?.toLocaleString() }}</template>
        </el-table-column>
        <el-table-column prop="likes" label="点赞量" width="120" sortable>
          <template #default="{ row }">{{ row.likes?.toLocaleString() }}</template>
        </el-table-column>
        <el-table-column prop="comments" label="评论量" width="120" />
      </el-table>
    </el-card>

    <!-- 热门话题排行 -->
    <el-card>
      <template #header><span>热门话题排行</span></template>
      <el-table :data="hotTopics" border v-loading="loading">
        <template #empty><el-empty description="暂无数据" /></template>
        <el-table-column type="index" label="排名" width="80" />
        <el-table-column prop="name" label="话题名称" min-width="200" />
        <el-table-column prop="post_count" label="动态数" width="120" sortable />
        <el-table-column prop="participant_count" label="参与人数" width="120" />
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

const loading = ref(false)
const metrics = ref({})
const hotSongs = ref([])
const hotTopics = ref([])

const loadData = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/admin/content-ops/data')
    if (res.data.code === 200) {
      const data = res.data.data
      metrics.value = data.metrics || {}
      hotSongs.value = data.hot_songs || []
      hotTopics.value = data.hot_topics || []
    }
  } catch (e) {
    console.error('加载内容运营数据失败', e)
  } finally {
    loading.value = false
  }
}

onMounted(() => loadData())
</script>

<style scoped>
.metric-card { text-align: center; }
.metric-card__title { font-size: 13px; color: #909399; margin-bottom: 8px; }
.metric-card__value { font-size: 28px; font-weight: bold; color: #303133; }
</style>

<template>
  <div>
    <h2 style="margin-bottom: 20px;">用户画像</h2>

    <!-- 用户搜索 -->
    <el-card style="margin-bottom: 20px;">
      <el-row :gutter="10">
        <el-col :span="8">
          <el-input v-model="userId" placeholder="输入用户ID" clearable @keyup.enter="loadProfile" />
        </el-col>
        <el-col :span="4">
          <el-button type="primary" @click="loadProfile" :loading="loading">查询</el-button>
        </el-col>
      </el-row>
    </el-card>

    <template v-if="profile">
      <!-- 用户基本信息 -->
      <el-card style="margin-bottom: 20px;">
        <template #header><span>用户信息</span></template>
        <el-row :gutter="20">
          <el-col :span="6">
            <div class="user-info">
              <el-avatar :size="80" :src="profile.user.avatar" />
              <div class="user-name">{{ profile.user.nickname }}</div>
              <div class="user-id">@{{ profile.user.username }}</div>
              <el-tag :type="profile.user.member_level === 2 ? 'danger' : profile.user.member_level === 1 ? 'warning' : 'info'" style="margin-top: 8px;">
                {{ profile.user.member_level === 2 ? 'SVIP' : profile.user.member_level === 1 ? 'VIP' : '普通用户' }}
              </el-tag>
            </div>
          </el-col>
          <el-col :span="18">
            <el-descriptions :column="3" border>
              <el-descriptions-item label="用户ID">{{ profile.user.id }}</el-descriptions-item>
              <el-descriptions-item label="邮箱">{{ profile.user.email || '-' }}</el-descriptions-item>
              <el-descriptions-item label="音币">{{ profile.user.coins }}</el-descriptions-item>
              <el-descriptions-item label="状态">
                <el-tag :type="profile.user.status === 0 ? 'success' : 'danger'">
                  {{ profile.user.status === 0 ? '正常' : '禁用' }}
                </el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="注册时间">{{ profile.user.created_at }}</el-descriptions-item>
            </el-descriptions>
          </el-col>
        </el-row>
      </el-card>

      <!-- 数据统计 -->
      <el-row :gutter="16" style="margin-bottom: 20px;">
        <el-col :span="3" v-for="stat in statCards" :key="stat.key">
          <el-card shadow="hover" class="stat-card">
            <div class="stat-value" :style="{ color: stat.color }">{{ profile.stats[stat.key] || 0 }}</div>
            <div class="stat-label">{{ stat.label }}</div>
          </el-card>
        </el-col>
      </el-row>

      <!-- 听歌偏好 + 最近活动 -->
      <el-row :gutter="16">
        <el-col :span="8">
          <el-card>
            <template #header><span>听歌风格偏好</span></template>
            <div v-if="profile.style_preferences?.length">
              <div v-for="pref in profile.style_preferences" :key="pref.style" class="pref-item">
                <span class="pref-name">{{ pref.style }}</span>
                <el-progress :percentage="Math.min(100, pref.count * 10)" :stroke-width="16" />
                <span class="pref-count">{{ pref.count }}首</span>
              </div>
            </div>
            <el-empty v-else description="暂无数据" :image-size="60" />
          </el-card>
        </el-col>
        <el-col :span="16">
          <el-card>
            <template #header><span>最近活动</span></template>
            <el-timeline v-if="profile.recent_activities?.length">
              <el-timeline-item
                v-for="(act, i) in profile.recent_activities"
                :key="i"
                :type="act.type === 'play' ? 'primary' : 'success'"
                :timestamp="act.created_at"
              >
                {{ act.content }}
              </el-timeline-item>
            </el-timeline>
            <el-empty v-else description="暂无活动" :image-size="60" />
          </el-card>
        </el-col>
      </el-row>
    </template>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

const userId = ref('')
const loading = ref(false)
const profile = ref(null)

const statCards = [
  { key: 'songs', label: '歌曲', color: '#409eff' },
  { key: 'posts', label: '动态', color: '#67c23a' },
  { key: 'comments', label: '评论', color: '#e6a23c' },
  { key: 'ai_tasks', label: 'AI创作', color: '#f56c6c' },
  { key: 'likes', label: '点赞', color: '#909399' },
  { key: 'following', label: '关注', color: '#b37feb' },
  { key: 'followers', label: '粉丝', color: '#36cfc9' },
  { key: 'play_count', label: '播放', color: '#ff85c0' }
]

const loadProfile = async () => {
  if (!userId.value) {
    ElMessage.warning('请输入用户ID')
    return
  }
  loading.value = true
  try {
    const res = await axios.get(`/api/admin/users/${userId.value}/profile`)
    if (res.data.code === 200) {
      profile.value = res.data.data
    } else {
      ElMessage.error(res.data.message || '用户不存在')
      profile.value = null
    }
  } catch (e) {
    ElMessage.error('查询失败')
    profile.value = null
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.user-info { text-align: center; }
.user-name { font-size: 18px; font-weight: bold; margin-top: 12px; }
.user-id { font-size: 13px; color: #909399; }
.stat-card { text-align: center; }
.stat-value { font-size: 24px; font-weight: bold; }
.stat-label { font-size: 12px; color: #909399; margin-top: 4px; }
.pref-item { display: flex; align-items: center; margin-bottom: 12px; }
.pref-name { width: 60px; font-size: 13px; }
.pref-count { width: 40px; text-align: right; font-size: 12px; color: #909399; }
.pref-item .el-progress { flex: 1; margin: 0 12px; }
</style>

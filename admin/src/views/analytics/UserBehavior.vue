<template>
  <div>
    <h2 style="margin-bottom: 20px;">用户行为分析</h2>

    <!-- 留存分析 -->
    <el-card style="margin-bottom: 20px;">
      <template #header><span>用户留存分析（真实数据）</span></template>
      <el-row :gutter="20">
        <el-col :span="8" v-for="item in retentionData" :key="item.period">
          <div class="retention-card">
            <div class="retention-rate" :class="{ good: parseFloat(item.rate) > 50, bad: parseFloat(item.rate) < 20 }">
              {{ item.rate }}%
            </div>
            <div class="retention-label">{{ item.period }}</div>
            <div class="retention-detail">{{ item.retained }}/{{ item.new_users }} 用户</div>
          </div>
        </el-col>
      </el-row>
    </el-card>

    <!-- 转化漏斗 -->
    <el-card style="margin-bottom: 20px;">
      <template #header><span>转化漏斗（真实数据）</span></template>
      <el-table :data="funnelData" border>
        <el-table-column prop="name" label="阶段" width="150" />
        <el-table-column prop="count" label="用户数" width="120" sortable />
        <el-table-column prop="rate" label="转化率" width="120">
          <template #default="{ row }">
            <el-tag :type="parseFloat(row.rate) > 30 ? 'success' : parseFloat(row.rate) > 10 ? 'warning' : 'danger'">
              {{ row.rate }}%
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="漏斗图">
          <template #default="{ row, $index }">
            <div class="funnel-bar" :style="{ width: row.rate + '%', background: colors[$index] }"></div>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 用户分群 -->
    <el-card>
      <template #header><span>用户分群</span></template>
      <el-row :gutter="16">
        <el-col :span="4" v-for="seg in segments" :key="seg.name">
          <el-card shadow="hover" class="segment-card">
            <div class="seg-count">{{ seg.count }}</div>
            <div class="seg-name">{{ seg.name }}</div>
            <div class="seg-desc">{{ seg.desc }}</div>
          </el-card>
        </el-col>
      </el-row>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

const retentionData = ref([])
const funnelData = ref([])
const segments = ref([])
const colors = ['#409eff', '#67c23a', '#e6a23c', '#f56c6c']

const loadRetention = async () => {
  try {
    const res = await axios.get('/api/admin/analytics/real-retention')
    if (res.data.code === 200) {
      const d = res.data.data
      retentionData.value = [
        { period: '次日留存', rate: d.day1.rate, retained: d.day1.retained, new_users: d.day1.new_users },
        { period: '7日留存', rate: d.day7.rate, retained: d.day7.retained, new_users: d.day7.new_users },
        { period: '30日留存', rate: d.day30.rate, retained: d.day30.retained, new_users: d.day30.new_users }
      ]
    }
  } catch (e) { console.error(e) }
}

const loadFunnel = async () => {
  try {
    const res = await axios.get('/api/admin/analytics/real-funnel')
    if (res.data.code === 200) funnelData.value = res.data.data.funnel
  } catch (e) { console.error(e) }
}

const loadSegments = async () => {
  try {
    const res = await axios.get('/api/admin/users/segments')
    if (res.data.code === 200) segments.value = res.data.data.segments
  } catch (e) { console.error(e) }
}

onMounted(() => {
  loadRetention()
  loadFunnel()
  loadSegments()
})
</script>

<style scoped>
.retention-card { text-align: center; padding: 20px; background: #f5f7fa; border-radius: 8px; }
.retention-rate { font-size: 36px; font-weight: bold; color: #409eff; }
.retention-rate.good { color: #67c23a; }
.retention-rate.bad { color: #f56c6c; }
.retention-label { font-size: 16px; margin: 8px 0 4px; }
.retention-detail { font-size: 12px; color: #909399; }
.funnel-bar { height: 24px; border-radius: 4px; min-width: 20px; }
.segment-card { text-align: center; }
.seg-count { font-size: 24px; font-weight: bold; color: #409eff; }
.seg-name { font-size: 14px; margin: 8px 0 4px; }
.seg-desc { font-size: 11px; color: #909399; }
</style>

<template>
  <div>
    <h2 style="margin-bottom: 20px;">敏感词管理</h2>

    <el-card style="margin-bottom: 20px;">
      <template #header>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span>敏感词库</span>
          <div>
            <el-button type="primary" size="small" @click="addWord">添加敏感词</el-button>
            <el-button type="success" size="small" @click="saveWords">保存到服务器</el-button>
          </div>
        </div>
      </template>

      <el-alert type="warning" :closable="false" style="margin-bottom: 16px;">
        敏感词用于自动检测用户发布的内容（动态、评论、歌词）。命中敏感词的内容将自动进入审核队列。
      </el-alert>

      <div class="word-tags">
        <el-tag v-for="(word, index) in words" :key="index" closable @close="removeWord(index)" style="margin: 4px;">
          {{ word }}
        </el-tag>
        <el-empty v-if="!words.length" description="暂无敏感词" :image-size="60" />
      </div>

      <div style="margin-top: 16px; color: #909399; font-size: 13px;">
        共 {{ words.length }} 个敏感词
      </div>
    </el-card>

    <el-card>
      <template #header><span>批量导入</span></template>
      <el-input v-model="batchInput" type="textarea" :rows="4" placeholder="每行一个敏感词，点击下方按钮批量导入" />
      <el-button type="primary" style="margin-top: 12px;" @click="batchImport">批量导入</el-button>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

const words = ref([])
const batchInput = ref('')

const loadData = async () => {
  try {
    const res = await axios.get('/api/admin/sensitive-words')
    if (res.data.code === 200) words.value = res.data.data.words || []
  } catch (e) { console.error(e) }
}

const addWord = async () => {
  const { value } = await ElMessageBox.prompt('请输入敏感词', '添加敏感词', { inputPattern: /\S+/, inputErrorMessage: '不能为空' })
  if (value && !words.value.includes(value)) {
    words.value.push(value)
  }
}

const removeWord = (index) => {
  words.value.splice(index, 1)
}

const batchImport = () => {
  const newWords = batchInput.value.split('\n').map(w => w.trim()).filter(w => w && !words.value.includes(w))
  words.value.push(...newWords)
  batchInput.value = ''
  ElMessage.success(`导入了 ${newWords.length} 个敏感词`)
}

const saveWords = async () => {
  try {
    await axios.post('/api/admin/sensitive-words', { words: words.value })
    ElMessage.success('保存成功')
  } catch (e) { ElMessage.error('保存失败') }
}

onMounted(() => loadData())
</script>

<style scoped>
.word-tags { min-height: 100px; }
</style>

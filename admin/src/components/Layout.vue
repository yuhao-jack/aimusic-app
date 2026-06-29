
<template>
  <el-container style="height: 100vh;">
    <el-aside width="200px" style="background-color: #2f3640;">
      <el-menu
        :default-active="$route.path"
        class="el-menu-vertical"
        background-color="#2f3640"
        text-color="#fff"
        active-text-color="#409eff"
        router
      >
        <template v-for="item in menuList" :key="item.path">
          <!-- 分组标题 -->
          <el-menu-item-group v-if="item.children">
            <template #title><span style="color: #909399;">{{ item.title }}</span></template>
            <el-menu-item v-for="child in item.children" :key="child.path" :index="child.path">
              <el-icon><component :is="child.icon" /></el-icon>
              <template #title>{{ child.title }}</template>
            </el-menu-item>
          </el-menu-item-group>
          <!-- 普通菜单项 -->
          <el-menu-item v-else :index="item.path">
            <el-icon><component :is="item.icon" /></el-icon>
            <template #title>{{ item.title }}</template>
          </el-menu-item>
        </template>
      </el-menu>
    </el-aside>
    <el-container>
      <el-header style="background-color: #fff; border-bottom: 1px solid #e6e6e6; display: flex; align-items: center; justify-content: space-between;">
        <div class="header-title">AI音乐APP 后台管理系统</div>
        <div>
          <el-button type="text" @click="handleLogout">退出登录</el-button>
        </div>
      </el-header>
      <el-main>
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'
import {
  HomeFilled, User, Microphone, MagicStick, ChatDotRound, Document, VideoCamera, CircleCheck, Setting, ShoppingCart, Coin, List, Picture, PriceTag, Warning, Lock, DataLine, Monitor, Bell, SetUp, TrendCharts, Operation, Wallet
} from '@element-plus/icons-vue'

const router = useRouter()

const menuList = [
  { path: '/dashboard', title: '仪表盘', icon: HomeFilled },
  { path: '/users', title: '用户管理', icon: User },
  { path: '/songs', title: '音乐管理', icon: Microphone },
  { path: '/ai-tasks', title: 'AI创作管理', icon: MagicStick },
  { path: '/comments', title: '评论管理', icon: ChatDotRound },
  { path: '/posts', title: '动态管理', icon: Document },
  { path: '/rooms', title: '一起听房间', icon: VideoCamera },
  { path: '/audit', title: '内容审核', icon: CircleCheck },
  {
    title: '商业化管理',
    children: [
      { path: '/members', title: '会员管理', icon: User },
      { path: '/vip-plans', title: 'VIP套餐', icon: ShoppingCart },
      { path: '/coin-packages', title: '音币充值包', icon: Coin },
      { path: '/coin-records', title: '音币记录', icon: List },
      { path: '/orders', title: '订单管理', icon: List }
    ]
  },
  { path: '/system/config', title: '系统配置', icon: Setting },
  {
    title: '运营管理',
    children: [
      { path: '/banners', title: 'Banner管理', icon: Picture },
      { path: '/topics', title: '话题管理', icon: PriceTag },
      { path: '/content-ops', title: '内容运营', icon: Operation }
    ]
  },
  {
    title: '风控管理',
    children: [
      { path: '/reports', title: '举报管理', icon: Warning },
      { path: '/bans', title: '封禁管理', icon: Lock }
    ]
  },
  {
    title: '数据统计',
    children: [
      { path: '/statistics/overview', title: '数据总览', icon: DataLine }
    ]
  },
  {
    title: '运营分析',
    children: [
      { path: '/analytics/user-behavior', title: '用户行为分析', icon: TrendCharts },
      { path: '/analytics/revenue', title: '营收分析', icon: Wallet }
    ]
  },
  {
    title: '运营监控',
    children: [
      { path: '/monitor/dashboard', title: '实时监控', icon: Monitor },
      { path: '/monitor/alerts', title: '告警管理', icon: Bell },
      { path: '/monitor/quota', title: '配额管理', icon: SetUp }
    ]
  }
]

const handleLogout = async () => {
  try {
    await ElMessageBox.confirm('确定要退出登录吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    localStorage.removeItem('admin_token')
    delete axios.defaults.headers.common['Authorization']
    ElMessage.success('退出登录成功')
    router.push('/login')
  } catch {
    // 用户取消
  }
}
</script>

<style scoped>
.el-header {
  padding: 0 20px;
}

.header-title {
  font-size: 18px;
  font-weight: bold;
  color: #333;
}

.el-aside {
  overflow-y: auto;
}
</style>

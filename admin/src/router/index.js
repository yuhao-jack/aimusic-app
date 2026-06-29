
import { createRouter, createWebHistory } from 'vue-router'
import Login from '../views/Login.vue'
import Dashboard from '../views/Dashboard.vue'
import Layout from '../components/Layout.vue'
import UserList from '../views/user/UserList.vue'
import SongList from '../views/song/SongList.vue'
import AiTaskList from '../views/ai/AiTaskList.vue'
import CommentList from '../views/comment/CommentList.vue'
import PostList from '../views/post/PostList.vue'
import RoomList from '../views/room/RoomList.vue'
import AuditList from '../views/audit/AuditList.vue'
import SystemConfig from '../views/system/Config.vue'
import MemberList from '../views/membership/MemberList.vue'
import VIPPlanList from '../views/membership/VIPPlanList.vue'
import CoinPackageList from '../views/membership/CoinPackageList.vue'
import CoinRecordList from '../views/membership/CoinRecordList.vue'
import OrderList from '../views/membership/OrderList.vue'
import BannerList from '../views/operation/BannerList.vue'
import TopicList from '../views/operation/TopicList.vue'
import ContentOps from '../views/operation/ContentOps.vue'
import UserBehavior from '../views/analytics/UserBehavior.vue'
import Revenue from '../views/analytics/Revenue.vue'
import ReportList from '../views/risk/ReportList.vue'
import BanList from '../views/risk/BanList.vue'
import StatisticsOverview from '../views/statistics/Overview.vue'
import MonitorDashboard from '../views/monitor/Monitor.vue'
import AlertList from '../views/monitor/AlertList.vue'
import QuotaConfig from '../views/monitor/QuotaConfig.vue'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: Login
  },
  {
    path: '/',
    component: Layout,
    redirect: '/dashboard',
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: Dashboard,
        meta: { title: '仪表盘' }
      },
      {
        path: 'users',
        name: 'UserList',
        component: UserList,
        meta: { title: '用户管理' }
      },
      {
        path: 'songs',
        name: 'SongList',
        component: SongList,
        meta: { title: '音乐管理' }
      },
      {
        path: 'ai-tasks',
        name: 'AiTaskList',
        component: AiTaskList,
        meta: { title: 'AI创作管理' }
      },
      {
        path: 'comments',
        name: 'CommentList',
        component: CommentList,
        meta: { title: '评论管理' }
      },
      {
        path: 'posts',
        name: 'PostList',
        component: PostList,
        meta: { title: '动态管理' }
      },
      {
        path: 'rooms',
        name: 'RoomList',
        component: RoomList,
        meta: { title: '一起听房间管理' }
      },
      {
        path: 'audit',
        name: 'AuditList',
        component: AuditList,
        meta: { title: '内容审核' }
      },
      {
        path: 'members',
        name: 'MemberList',
        component: MemberList,
        meta: { title: '会员管理' }
      },
      {
        path: 'vip-plans',
        name: 'VIPPlanList',
        component: VIPPlanList,
        meta: { title: 'VIP套餐管理' }
      },
      {
        path: 'coin-packages',
        name: 'CoinPackageList',
        component: CoinPackageList,
        meta: { title: '音币充值包管理' }
      },
      {
        path: 'coin-records',
        name: 'CoinRecordList',
        component: CoinRecordList,
        meta: { title: '音币记录' }
      },
      {
        path: 'orders',
        name: 'OrderList',
        component: OrderList,
        meta: { title: '订单管理' }
      },
      {
        path: 'system/config',
        name: 'SystemConfig',
        component: SystemConfig,
        meta: { title: '系统配置' }
      },
      {
        path: 'banners',
        name: 'BannerList',
        component: BannerList,
        meta: { title: 'Banner管理' }
      },
      {
        path: 'topics',
        name: 'TopicList',
        component: TopicList,
        meta: { title: '话题管理' }
      },
      {
        path: 'content-ops',
        name: 'ContentOps',
        component: ContentOps,
        meta: { title: '内容运营' }
      },
      {
        path: 'reports',
        name: 'ReportList',
        component: ReportList,
        meta: { title: '举报管理' }
      },
      {
        path: 'bans',
        name: 'BanList',
        component: BanList,
        meta: { title: '封禁管理' }
      },
      {
        path: 'statistics/overview',
        name: 'StatisticsOverview',
        component: StatisticsOverview,
        meta: { title: '数据总览' }
      },
      {
        path: 'analytics/user-behavior',
        name: 'UserBehavior',
        component: UserBehavior,
        meta: { title: '用户行为分析' }
      },
      {
        path: 'analytics/revenue',
        name: 'Revenue',
        component: Revenue,
        meta: { title: '营收分析' }
      },
      {
        path: 'monitor/dashboard',
        name: 'MonitorDashboard',
        component: MonitorDashboard,
        meta: { title: '实时监控' }
      },
      {
        path: 'monitor/alerts',
        name: 'AlertList',
        component: AlertList,
        meta: { title: '告警管理' }
      },
      {
        path: 'monitor/quota',
        name: 'QuotaConfig',
        component: QuotaConfig,
        meta: { title: '配额管理' }
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫，检查登录状态
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('admin_token')
  if (to.path !== '/login' && !token) {
    next('/login')
  } else {
    next()
  }
})

export default router

# MyMemories 项目概览

## 项目简介

MyMemories (Hixy_MyMemories) 是一个基于 HarmonyOS 的纪念日和倒数日管理应用。该应用允许用户记录重要的日期事件，如生日、纪念日、重要事件的倒数日等，并提供直观的界面展示距离这些事件还有多少天或已经过去多少天。

### 项目基本信息
- **项目名称**: MyMemories (Hixy_MyMemories)
- **开发语言**: ArkTS
- **目标平台**: HarmonyOS
- **应用类型**: 日期管理应用
- **开发工具**: DevEco Studio 6.0.1.260

## 项目结构

### 文档结构
本项目包含以下文档：

1. **[DOCUMENTATION.md](./DOCUMENTATION.md)** - 项目详细文档，包含架构、功能说明等
2. **[API_REFERENCE.md](./API_REFERENCE.md)** - API参考文档，详细说明核心类和方法
3. **[USER_GUIDE.md](./USER_GUIDE.md)** - 用户使用指南，帮助用户了解如何使用应用
4. **[DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md)** - 开发者指南，详细介绍如何扩展和维护项目
5. **[README.md](./README.md)** - 项目说明文件（当前文件）

### 代码结构
```
Hixy_MyMemories/
├── AppScope/                 # 应用级资源
├── entry/                    # 应用入口模块
│   ├── src/main/ets/         # ArkTS 源代码
│   │   ├── entryability/     # 应用入口
│   │   ├── pages/            # 页面组件
│   │   ├── store/            # 数据存储
│   │   ├── types/            # 类型定义
│   │   └── utils/            # 工具函数
│   └── ...
├── README.md                 # 项目说明
├── DOCUMENTATION.md          # 项目文档
├── API_REFERENCE.md          # API参考
├── USER_GUIDE.md             # 用户指南
├── DEVELOPER_GUIDE.md        # 开发者指南
└── PROJECT_OVERVIEW.md       # 项目概览（当前文件）
```

## 核心功能

### 1. 记忆管理
- **添加记忆**: 支持添加倒数日和纪念日
- **编辑记忆**: 修改已有的记忆事件
- **删除记忆**: 安全删除记忆事件（带确认机制）
- **查看记忆**: 详细查看记忆信息

### 2. 智能显示
- **分类显示**: 倒数日（蓝色）和纪念日（橙色）颜色区分
- **统计信息**: 显示即将到来的事件和已过去的记忆数量
- **距离计算**: 自动计算距离目标日期的天数

### 3. 数据持久化
- **本地数据库**: 使用 HarmonyOS RDB 存储数据
- **数据安全**: 多重备份机制防止数据丢失
- **同步机制**: 自动同步数据库和UI状态

## 技术特点

### 架构设计
- **分层架构**: UI层、状态层、服务层、数据层
- **组件化设计**: 高度模块化的UI组件
- **响应式状态**: 基于AppStorage的状态管理
- **异步操作**: 所有数据库操作均为异步

### 用户体验
- **直观界面**: 清晰的视觉层次和操作流程
- **快速响应**: 异步数据库操作，不阻塞UI
- **数据安全**: 多重备份机制确保数据安全
- **交互友好**: 确认机制避免误操作

## 开发指南

### 环境准备
1. 安装 DevEco Studio 6.0.1.260 或更高版本
2. 配置 HarmonyOS SDK
3. 确保 Node.js 环境可用

### 构建和运行
```bash
# 进入项目目录
cd Hixy_MyMemories/entry

# 构建项目
hvigor build

# 在模拟器或真机上运行
# 使用 DevEco Studio 的 Run 功能
```

### 代码贡献
1. 遵循项目代码规范
2. 编写必要的单元测试
3. 更新相关文档
4. 提交代码审查

## 文档索引

### 用户文档
- **[USER_GUIDE.md](./USER_GUIDE.md)**: 详细说明如何使用应用功能
- **[DOCUMENTATION.md](./DOCUMENTATION.md)**: 项目整体功能说明

### 开发文档
- **[API_REFERENCE.md](./API_REFERENCE.md)**: 核心API详细说明
- **[DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md)**: 开发和维护指南

### 项目信息
- **[README.md](./README.md)**: 项目基本信息
- **[PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md)**: 项目概览（当前文件）

## 项目状态

### 已实现功能
- ✅ 记忆事件的增删改查
- ✅ 倒数日和纪念日分类管理
- ✅ 数据库持久化存储
- ✅ 直观的UI界面
- ✅ 数据同步机制
- ✅ 错误处理和用户反馈

### 未来计划
- 📅 通知提醒功能
- 📅 数据备份和同步
- 📅 图片附件支持
- 📅 多语言国际化

## 贡献者

- **开发者**: 小影团队
- **联系方式**: hi@xyw.cx
- **GitHub**: github.com/hiyuey3

## 许可证

本项目为学习和演示目的开发，遵循相关开源协议。

---

**最后更新**: 2025-12-26  
**文档版本**: 1.0
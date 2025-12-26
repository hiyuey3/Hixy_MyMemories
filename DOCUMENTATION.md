# MyMemories 应用 - 项目文档

## 项目概述

MyMemories 是一个基于 HarmonyOS 的应用程序，用于记录和管理重要的纪念日和倒数日。该应用允许用户添加、编辑和删除记忆事件，并提供倒数日和纪念日两种类型的记忆记录。

### 项目基本信息
- **项目名称**: MyMemories (Hixy_MyMemories)
- **开发语言**: ArkTS
- **目标平台**: HarmonyOS
- **开发工具**: DevEco Studio
- **主要功能**: 记录和管理纪念日/倒数日

## 项目架构

### 目录结构
```
Hixy_MyMemories/
├── AppScope/                 # 应用级资源
│   └── resources/
├── entry/                    # 应用入口模块
│   ├── src/
│   │   ├── main/
│   │   │   ├── ets/          # ArkTS 源代码
│   │   │   │   ├── entryability/     # 应用入口
│   │   │   │   ├── pages/            # 页面组件
│   │   │   │   ├── store/            # 数据存储
│   │   │   │   ├── types/            # 类型定义
│   │   │   │   └── utils/            # 工具函数
│   │   │   └── resources/    # 应用资源
│   └── ...
├── README.md                 # 项目说明
└── hvigorfile.ts            # 构建配置
```

### 核心技术栈
- **UI框架**: ArkUI (声明式UI)
- **数据库**: HarmonyOS关系型数据库(RDB)
- **编程语言**: ArkTS
- **状态管理**: AppStorage

## 核心功能模块

### 1. 主页 (Index.ets)
主页是应用的主要界面，提供以下功能：

- **记忆列表**: 显示所有记忆事件，按时间排序
- **统计信息**: 显示即将到来的事件数量和已过去的记忆数量
- **导航标签**: 提供首页、记忆、关于三个标签页
- **新增按钮**: 快速添加新的记忆事件
- **管理按钮**: 进入记忆管理页面

#### 功能特点
- 使用 Tabs 组件实现多标签页导航
- 动态加载数据库中的记忆事件
- 响应式UI设计，适配不同屏幕尺寸
- 生命周期管理确保数据同步

### 2. 数据库工具 (MemDBUtils.ets)
提供对 HarmonyOS RDB 数据库的封装操作：

- **数据库初始化**: 创建和配置数据库
- **CRUD操作**: 增删改查记忆事件
- **类型定义**: Memory 类定义数据库记录结构
- **异步操作**: 所有数据库操作均为异步

#### 核心方法
- `initMemoryDB()`: 初始化数据库
- `insertMemory()`: 插入新记忆
- `queryMemories()`: 查询记忆列表
- `deleteMemoryById()`: 按ID删除记忆
- `updateMemoryById()`: 更新记忆

### 3. 数据类型定义 (MemoryTypes.ts)
定义应用中使用的类型：

```typescript
export type MemoryType = 'countdown' | 'anniversary';
export interface MemoryItem {
  id: number;
  title: string;
  date: Date;
  type: MemoryType;
  note?: string;
}
```

### 4. 记忆商店 (MemoryStore.ets)
应用的状态管理器：

- **数据管理**: 维护记忆事件列表
- **数据库同步**: 与数据库保持同步
- **事件通知**: 订阅模式通知UI更新
- **备份机制**: 提供本地备份作为数据安全网

### 5. 页面功能

#### 添加记忆 (AddMemory.ets)
- 标题输入
- 日期选择
- 类型选择（倒数日/纪念日）
- 数据验证和保存

#### 编辑记忆 (EditMemory.ets)
- 加载现有记忆数据
- 编辑标题、日期、类型
- 保存修改到数据库
- 参数传递机制（路由参数和AppStorage）

#### 事件详情 (EventDetail.ets)
- 显示单个记忆的详细信息
- 编辑和删除功能
- 参数获取机制

#### 记忆管理 (ManageMemories.ets)
- 记忆列表展示
- 编辑功能
- 删除确认机制
- 内联确认UI

#### 设置页面 (Settings.ets)
- 通知设置
- 提醒天数设置
- 数据保存

#### 关于页面 (About.ets)
- 应用信息展示
- 开发者信息
- 版本信息

## 数据库设计

### 表结构
```
表名: memories
- id: integer (主键，自增)
- task_name: text (记忆标题)
- finished: boolean (是否为纪念日，0=倒数日，1=纪念日)
```

### 数据映射
- `task_name` → MemoryItem.title
- `finished` → MemoryItem.type (0=countdown, 1=anniversary)
- `id` → MemoryItem.id

## 状态管理

### AppStorage
- `selectedId`: 当前选中的记忆ID
- `headerImagePath`: 页眉图片路径
- `needsReload`: 是否需要重新加载数据
- `mem_backup`: 本地备份数据

### 订阅模式
- MemoryDBUtil 提供订阅机制
- UI组件可以订阅数据库变化
- 自动更新UI以反映数据变化

## UI组件设计

### 组件结构
- **Index**: 主页，包含标签页导航
- **EventCard**: 记忆列表项组件
- **AddMemory**: 添加记忆页面
- **EditMemory**: 编辑记忆页面
- **EventDetail**: 事件详情页面
- **ManageMemories**: 记忆管理页面
- **Settings**: 设置页面
- **About**: 关于页面

### 装饰器使用
- `@Entry`: 组件入口点
- `@Component`: UI组件定义
- `@State`: 组件内部状态
- `@StorageProp`: AppStorage绑定属性
- `@Link`: 链接状态
- `@Builder`: 构建函数

## 生命周期管理

### 页面生命周期
- `onInit()`: 组件初始化
- `onShow()`: 页面显示时
- `aboutToAppear()`: 组件即将显示
- `onDestroy()`: 组件销毁

### 数据同步策略
- 页面显示时同步数据库
- 操作后延迟同步确保数据一致性
- 订阅数据库变化自动更新UI

## 错误处理和用户反馈

### 错误处理机制
- 数据库操作异常捕获
- 用户输入验证
- Toast消息提示
- 控制台日志记录

### 用户反馈
- Toast提示消息
- 操作状态反馈
- 错误信息显示

## 项目配置

### 权限配置
- 震动权限 (ohos.permission.VIBRATE) - 用于删除确认

### 构建配置
- 使用 hvigor 构建系统
- 支持预览和调试模式

## 开发和测试

### 开发环境
- DevEco Studio 6.0.1.260
- HarmonyOS SDK
- TypeScript/ArkTS 支持

### 测试策略
- 单元测试 (位于 src/ohosTest 和 src/test)
- 手动测试流程
- 数据库操作验证

## 部署和发布

### 构建命令
```bash
hvigor build
```

### 安装包
- 生成 .hap 文件
- 支持模拟器和真机部署

## 项目特点和优势

### 技术特点
1. **声明式UI**: 使用ArkUI框架，代码简洁易读
2. **数据驱动**: 基于状态管理的响应式设计
3. **本地存储**: 使用HarmonyOS RDB进行数据持久化
4. **组件化**: 高度模块化的组件设计

### 用户体验
1. **直观界面**: 清晰的视觉层次和操作流程
2. **快速响应**: 异步数据库操作，不阻塞UI
3. **数据安全**: 多重备份机制确保数据安全
4. **交互友好**: 确认机制避免误操作

## 后续改进方向

### 功能扩展
- 添加记忆详情和备注功能
- 支持图片附件
- 添加通知提醒功能
- 数据备份和同步

### 技术优化
- 性能优化
- 代码重构和模块化
- 单元测试覆盖
- 错误处理完善

### 用户体验
- 界面美化
- 交互优化
- 多语言支持
- 无障碍访问

## 常见问题和解决方案

### 数据库问题
- 数据库初始化失败：检查Context是否正确传递
- 查询结果为空：确认数据库表已创建且有数据

### UI问题
- 状态不更新：检查AppStorage和订阅机制
- 组件渲染异常：检查装饰器使用和参数传递

### 导航问题
- 页面跳转失败：检查路由URI是否正确
- 参数传递失败：使用路由参数和AppStorage双重机制

## 版权和许可

本项目为学习和演示目的开发，遵循相关开源协议。

---

**开发者**: 小影团队  
**联系方式**: hi@xyw.cx  
**版本**: v1.0.0  
**GitHub**: github.com/hiyuey3
# MyMemories 开发者指南

## 项目概述

本指南面向希望参与 MyMemories 项目开发、扩展功能或维护代码的开发者。本文档详细介绍了项目的架构、开发流程、代码规范和扩展方法。

## 技术栈

### 核心技术
- **开发语言**: ArkTS
- **UI框架**: ArkUI (声明式UI)
- **数据库**: HarmonyOS RDB (关系型数据库)
- **状态管理**: AppStorage + 自定义Store
- **构建工具**: Hvigor
- **运行环境**: HarmonyOS

### 开发环境
- **IDE**: DevEco Studio 6.0.1.260 或更高版本
- **SDK**: HarmonyOS SDK
- **Node.js**: 用于构建工具
- **TypeScript**: 语言支持

## 项目架构

### 分层架构

```
┌─────────────────┐
│   UI Layer      │  Pages, Components
├─────────────────┤
│  State Layer    │  MemoryStore, AppStorage
├─────────────────┤
│  Service Layer  │  MemDBUtils
├─────────────────┤
│  Data Layer     │  HarmonyOS RDB
└─────────────────┘
```

### 模块说明

#### UI层 (Pages & Components)
- **职责**: 用户界面展示和交互
- **技术**: ArkUI声明式语法
- **位置**: `entry/src/main/ets/pages/`

#### 状态层 (Store)
- **职责**: 应用状态管理
- **技术**: 自定义Store + AppStorage
- **位置**: `entry/src/main/ets/store/`

#### 服务层 (Utils)
- **职责**: 业务逻辑处理
- **技术**: 数据库操作封装
- **位置**: `entry/src/main/ets/utils/`

#### 数据层 (Database)
- **职责**: 数据持久化
- **技术**: HarmonyOS RDB
- **实现**: 系统级数据库

## 代码结构详解

### 项目目录结构
```
entry/
├── src/
│   ├── main/
│   │   ├── ets/
│   │   │   ├── entryability/      # 应用入口
│   │   │   ├── pages/            # 页面组件
│   │   │   ├── store/            # 状态管理
│   │   │   ├── types/            # 类型定义
│   │   │   └── utils/            # 工具函数
│   │   └── resources/            # 资源文件
│   └── ohosTest/                 # 测试文件
```

### 核心文件说明

#### MemoryDBUtils.ets
- **功能**: 数据库操作封装
- **主要类**: MemoryDBUtil
- **职责**: 
  - 数据库初始化
  - CRUD操作封装
  - 异步操作管理
  - 订阅通知机制

#### MemoryStore.ets
- **功能**: 应用状态管理
- **主要类**: MemoryStoreClass
- **职责**:
  - 内存数据管理
  - 数据同步
  - 事件通知
  - 本地备份

#### Index.ets
- **功能**: 应用主页
- **主要组件**: Index
- **职责**:
  - 主界面展示
  - 导航控制
  - 数据加载
  - 用户交互

## 开发规范

### 代码规范

#### ArkTS 代码风格
```typescript
// 组件命名使用PascalCase
@Component
struct MyComponent {
  // 状态变量使用camelCase
  @State myVariable: string = '';
  
  // 方法使用camelCase
  private myMethod(): void {
    // 代码实现
  }
}
```

#### 文件命名
- 组件文件: `[ComponentName].ets`
- 工具类: `[UtilityName].ets`
- 类型定义: `[TypeName].ts`
- 页面: `[PageName].ets`

#### 注释规范
```typescript
/**
 * 功能描述
 * @param param1 参数说明
 * @returns 返回值说明
 */
private myFunction(param1: string): boolean {
  // 单行注释说明复杂逻辑
  return true;
}
```

### 组件设计原则

#### 组件化原则
1. **单一职责**: 每个组件只负责一个功能
2. **可复用性**: 组件应设计为可复用
3. **可测试性**: 组件应易于单元测试
4. **可维护性**: 代码结构清晰，易于理解

#### 状态管理原则
1. **最小化状态**: 只保留必要的状态
2. **状态不可变性**: 避免直接修改状态对象
3. **状态一致性**: 确保内存状态与数据库状态同步
4. **错误处理**: 完善的错误处理机制

## 数据库设计

### 表结构

#### memories 表
| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | integer | 主键，自增 |
| task_name | text | 记忆标题 |
| finished | boolean | 是否为纪念日 (0=倒数日, 1=纪念日) |

### 数据映射关系
```typescript
// 数据库字段 -> 应用模型
task_name -> MemoryItem.title
finished -> MemoryItem.type
id -> MemoryItem.id
```

### 数据库操作最佳实践

#### 查询操作
```typescript
// 使用投影查询减少数据传输
const cols: string[] = ['id', 'task_name', 'finished'];
const rows: Memory[] = await MemoryDBUtil.queryMemories('memories', cols);
```

#### 异步操作
```typescript
// 所有数据库操作都应为异步
private async loadData(): Promise<void> {
  try {
    // 数据库操作
  } catch (error) {
    // 错误处理
  }
}
```

## 扩展开发

### 添加新功能

#### 1. 添加新页面
```typescript
// 1. 创建新页面组件
@Entry
@Component
struct NewPage {
  @State data: DataType[] = [];
  
  build() {
    // 页面UI
  }
}

// 2. 在路由中注册
// 3. 添加导航链接
```

#### 2. 扩展数据模型
```typescript
// 扩展现有类型定义
export interface MemoryItem {
  id: number;
  title: string;
  date: Date;
  type: MemoryType;
  note?: string;
  // 添加新字段
  newField?: string;
}
```

#### 3. 扩展数据库
```typescript
// 修改表结构时需要考虑向后兼容
const SQL_ALTER_TABLE = `ALTER TABLE memories ADD COLUMN new_column TEXT`;
```

### 性能优化

#### UI性能优化
1. **列表优化**: 使用 ForEach 和 ListItem
2. **状态最小化**: 只更新必要的状态
3. **懒加载**: 对于大量数据采用分页或懒加载

#### 数据库性能优化
1. **索引优化**: 为常用查询字段添加索引
2. **查询优化**: 使用投影查询减少数据传输
3. **批量操作**: 对于大量数据使用批量操作

### 错误处理

#### 数据库错误处理
```typescript
try {
  const result = await MemoryDBUtil.insertMemory('memories', values);
} catch (error) {
  console.error('Database operation failed:', error);
  // 实现降级策略
  this.fallbackToLocalStorage();
}
```

#### UI错误处理
```typescript
// 使用try-catch包装可能出错的操作
private safeOperation(): void {
  try {
    // 可能出错的操作
  } catch (error) {
    promptAction.showToast({ 
      message: '操作失败，请重试' 
    });
  }
}
```

## 测试策略

### 单元测试
- **位置**: `entry/src/ohosTest/` 和 `entry/src/test/`
- **框架**: HarmonyOS测试框架
- **覆盖范围**: 工具函数、业务逻辑

### 集成测试
- **页面交互**: UI组件交互测试
- **数据流**: 端到端数据流测试
- **数据库**: CRUD操作完整性测试

### 测试示例
```typescript
// 示例测试用例
describe('MemoryDBUtils', () => {
  it('should insert memory successfully', async () => {
    const values = { task_name: 'Test', finished: 0 };
    const id = await MemoryDBUtil.insertMemory('memories', values);
    expect(id).toBeGreaterThan(0);
  });
});
```

## 部署和发布

### 构建流程
```bash
# 开发构建
hvigor build

# 生产构建
hvigor build --mode release
```

### 包生成
- **HAP文件**: HarmonyOS应用包
- **签名**: 需要正确的应用签名
- **权限**: 确保权限配置正确

### 发布检查清单
- [ ] 代码审查完成
- [ ] 测试用例通过
- [ ] 性能测试通过
- [ ] 安全检查完成
- [ ] 用户文档更新

## 维护指南

### 代码维护
1. **定期重构**: 改进代码结构和性能
2. **依赖更新**: 定期更新HarmonyOS SDK
3. **文档同步**: 保持文档与代码同步
4. **错误修复**: 及时修复发现的问题

### 数据库维护
1. **备份策略**: 实现数据备份机制
2. **版本迁移**: 数据库结构变更时的迁移
3. **性能监控**: 监控数据库性能
4. **空间管理**: 定期清理无用数据

### 版本管理
- **分支策略**: 使用Git Flow工作流
- **标签管理**: 为每个发布版本打标签
- **变更日志**: 维护详细的变更日志

## 调试技巧

### 常用调试方法
1. **日志输出**: 使用console.log输出调试信息
2. **断点调试**: 使用DevEco Studio调试器
3. **性能分析**: 使用HarmonyOS性能分析工具
4. **UI检查**: 检查UI渲染和布局

### 常见问题排查
```typescript
// 数据库连接问题
if (!this.rdbStore) {
  console.log('Database not initialized');
  // 检查初始化流程
}

// 状态同步问题
// 确保在适当时候调用notify()方法
```

## 贡献指南

### 代码贡献流程
1. Fork项目
2. 创建功能分支
3. 实现功能
4. 编写测试
5. 提交PR
6. 代码审查
7. 合并代码

### 代码审查标准
- 代码风格符合规范
- 功能实现正确
- 错误处理完善
- 性能考虑周全
- 文档更新完整

## 未来发展方向

### 功能扩展
- 通知提醒功能
- 数据备份同步
- 图片附件支持
- 多语言支持

### 技术优化
- 性能优化
- 代码重构
- 测试覆盖提升
- 文档完善

### 架构改进
- 组件化程度提升
- 状态管理优化
- 数据库性能提升
- 用户体验改进

## 常见问题解答

### Q: 如何添加新的数据库字段？
**A**: 
1. 修改数据库表结构
2. 更新数据模型定义
3. 修改CRUD操作以支持新字段
4. 更新UI以显示新字段

### Q: 如何处理数据库升级？
**A**: 
1. 使用ALTER TABLE语句修改表结构
2. 实现版本迁移逻辑
3. 确保向后兼容性
4. 测试数据完整性

### Q: 如何优化列表性能？
**A**: 
1. 使用高效的列表组件
2. 实现虚拟滚动
3. 优化数据加载
4. 减少不必要的重渲染

---

**文档版本**: 1.0  
**最后更新**: 2025-12-26  
**适用开发者**: HarmonyOS应用开发者
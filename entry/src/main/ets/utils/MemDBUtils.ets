import { relationalStore } from '@kit.ArkData'
import { BusinessError } from '@kit.BasicServicesKit'

// 草泥马，煞笔开发者文档，尼玛的版本混乱的跟屎一样
/**
 * Memory 模型：表示一条记忆 / 任务记录
 * - 保持与现有数据库表字段兼容（id, task_name, finished）
 * - 可以在对象级别携带额外可选字段（content, createdAt）以便扩展
 */
export class Memory {
  id: number
  title: string
  finished: boolean
  content?: string
  createdAt?: number
  // 用户选择的日期，unix时间戳格式（毫秒）
  targetDate?: number

  constructor(id: number, title: string, finished: boolean, content?: string, createdAt?: number, targetDate?: number) {
    this.id = id
    this.title = title
    this.finished = finished
    this.content = content
    this.createdAt = createdAt
    this.targetDate = targetDate
  }

}

export class MemoryDBUtils {
  // 定义数据库变量
  private rdbStore: relationalStore.RdbStore | null = null
  // 当 rdbStore 可用时解析的 Promise
  private readyPromise: Promise<void> = Promise.resolve()
  private readyResolve?: () => void
  // 轻量级更改监听器，使页面可以响应数据库更改
  private listeners: Array<() => void> = []
  private notifyChange(): void {
    for (const cb of this.listeners) {
      try { cb() } catch (e) { console.log('MemDBUtils listener error', e) }
    }
  }
  subscribe(cb: () => void): () => void {
    this.listeners.push(cb)
    return () => {
      const i = this.listeners.indexOf(cb)
      if (i >= 0) this.listeners.splice(i, 1)
    }
  }

  // 初始化数据库
  // 包括两个参数:
  //   context: 上下文对象
  //   tableName: 数据库名称
  initMemoryDB(context: Context, tableName: string) {
    // 创建一个调用者可以等待的准备就绪承诺
    this.readyPromise = new Promise<void>((resolve) => { this.readyResolve = resolve })
    // (1) 初始化数据库配置
    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'hixy.db', // 数据库文件名
      securityLevel: relationalStore.SecurityLevel.S1 // 数据库安全级别
    }

    // (2) 定义SQL语句
    const SQL_CREATE_TABLE = `create table if not exists ${tableName} (
      id integer primary key autoincrement,
      task_name text not null,
      finished boolean,
      target_date number,
      content text
    )`

    // (3) 初始化数据库
    relationalStore.getRdbStore(context, STORE_CONFIG, (err, store) => {
      // 获取/创建 RDB / 打开 RDB
      if (err) {
        console.log(`获取taskdb失败, code: ${err.code}, message: ${err.message}`)
        // 解析准备状态以避免死锁；由于 rdbStore 为空，操作仍会失败
        if (this.readyResolve) { this.readyResolve() }
        return
      }

      console.log('创建rdbStore成功')
      this.rdbStore = store
      // 创建表然后解析准备状态（避免在表存在之前进行竞争）
      this.rdbStore.executeSql(SQL_CREATE_TABLE, (err) => {
        if (!err) {
          console.log(`创建${tableName}成功`)
          // 仅在表创建后发出就绪信号
          if (this.readyResolve) { this.readyResolve() }
        } else {
          console.log(`创建${tableName}失败`)
          // 仍解析以避免死锁；后续操作将记录 rdbStore 存在但表错误
          if (this.readyResolve) { this.readyResolve() }
        }
      })
      // 尝试添加 target_date 列（如果尚不存在）；忽略错误
      try {
        const SQL_ADD_COLUMN_TARGET = `alter table ${tableName} add column target_date integer`;
        this.rdbStore.executeSql(SQL_ADD_COLUMN_TARGET, (colErr) => {
          if (!colErr) {
            console.log(`确保 ${tableName}.target_date 列存在: 添加成功`)
          } else {
            console.log(`尝试添加 target_date 列返回: ${colErr.message}`)
          }
        })
        const SQL_ADD_COLUMN_CONTENT = `alter table ${tableName} add column content text`;
        this.rdbStore.executeSql(SQL_ADD_COLUMN_CONTENT, (colErr2) => {
          if (!colErr2) {
            console.log(`确保 ${tableName}.content 列存在: 添加成功`)
          } else {
            console.log(`尝试添加 content 列返回: ${colErr2.message}`)
          }
        })
      } catch (alterErr) {
        console.log('尝试添加列时抛出异常，忽略:', alterErr)
      }
    })
  }

  // 将数据插入到数据库，返回 Promise<rowId>
  async insertMemory(tableName: string, value: relationalStore.ValuesBucket): Promise<number> {
    console.log('insertMemory: waiting for DB ready...')
    await this.readyPromise
    console.log('insertMemory: readyPromise resolved, rdbStore is', this.rdbStore ? 'present' : 'null')
    console.log('insertMemory: inserting into', tableName, 'value=', JSON.stringify(value))
    return new Promise<number>((resolve, reject) => {
      if (!this.rdbStore) {
        console.log('insertMemory: rdbStore is null, rejecting')
        reject(new Error('rdbStore is null'))
        return
      }
      try {
        this.rdbStore.insert(tableName, value, (err: BusinessError, rowId: number) => {
          if (err) {
            console.log(`${tableName}数据库表数据添加失败: ${err.message}`)
            reject(err)
            return
          }
          console.log(`${tableName}表数据添加成功, rowId: ${rowId}`)
          // 通知监听器数据库内容已更改
          try { this.notifyChange() } catch (_) {}
          resolve(rowId)
        })
      } catch (callErr) {
        console.log('insertMemory: insert call threw', callErr)
        reject(callErr)
      }
    })
  }

  // 查询数据并返回 Memory[]
  async queryMemories(tableName: string, column: Array<string>): Promise<Memory[]> {
    await this.readyPromise
    if (this.rdbStore === null) {
      return []
    }

    try {
      let queryPredicates = new relationalStore.RdbPredicates(tableName)
      // 首先返回最新的，以便 UI 在顶部显示最近的添加
      try { queryPredicates.orderByDesc('id') } catch (e) { /* 某些 SDK 可能不支持 orderByDesc */ }
      const resultSet = await (this.rdbStore as relationalStore.RdbStore).query(queryPredicates, column)
      let memories: Memory[] = []

      try {
        // 使用与创建表时一致的列名: id, task_name, finished
        for (;;) {
          // 把可能抛异常的调用放在 try/catch 中，避免在循环条件中直接调用
          let hasNext: boolean
          try {
            hasNext = resultSet.goToNextRow()
          } catch (rowErr) {
            console.log(`遍历resultSet时出错: ${rowErr}`)
            break
          }

          if (!hasNext) {
            break
          }

          try {
            // 注意数据库中的列名为小写 'id' / 'task_name' / 'finished'
            const idIndex = resultSet.getColumnIndex('id')
            const nameIndex = resultSet.getColumnIndex('task_name')
            const finishedIndex = resultSet.getColumnIndex('finished')

            const targetDateIndex = resultSet.getColumnIndex('target_date')
            const contentIndex = resultSet.getColumnIndex('content')

            // 如果存在 id 列则读取其 long 值作为 memoryId；避免旧表不存在该列，
            // 此处使用 0 作为安全默认值以保证构造 Memory 对象时不会出现 undefined。
            // （注意：数据库中的字段名为小写 'id'，因此使用 getColumnIndex('id')）

            const memoryId = idIndex >= 0 ? resultSet.getLong(idIndex) : 0
            const title = nameIndex >= 0 ? resultSet.getString(nameIndex) : ''
            const finishedVal = finishedIndex >= 0 ? resultSet.getLong(finishedIndex) : 0
            const targetDateVal = targetDateIndex >= 0 ? resultSet.getLong(targetDateIndex) : undefined
            const contentVal = contentIndex >= 0 ? resultSet.getString(contentIndex) : undefined

            // 将数据库列映射到 Memory 对象：task_name -> title, target_date -> targetDate, content -> content
            memories.push(new Memory(memoryId, title, !!finishedVal, contentVal, undefined, targetDateVal))
          } catch (parseErr) {
            // 读取当前行时出现异常，记录并继续下一行
            console.log(`读取resultSet行数据失败: ${parseErr}`)
            continue
          }
        }

        console.log(`数据库查询结果(${memories.length}条) ${JSON.stringify(memories)}`)
        return memories
      } finally {
        // 确保 resultSet 始终关闭，任何异常都在外层捕获
        try {
          resultSet.close()
        } catch (closeErr) {
          console.log(`关闭resultSet失败: ${closeErr}`)
        }
      }
    } catch (err) {
      console.log(`查询数据库失败: ${err}`)
      return []
    }
  }

  async deleteMemoryById(tableName: string, memoryId: number): Promise<number> {
    console.log('deleteMemoryById: waiting for DB ready...')
    await this.readyPromise
    console.log('deleteMemoryById: ready, rdbStore is', this.rdbStore ? 'present' : 'null', 'id=', memoryId)
    return new Promise<number>((resolve, reject) => {
      const queryPredicates = new relationalStore.RdbPredicates(tableName)

      queryPredicates.equalTo('id', memoryId)
      if (!this.rdbStore) {
        console.log('deleteMemoryById: rdbStore 为空')
        reject(new Error('rdbStore is null'))
        return
      }
      try {
        this.rdbStore.delete(queryPredicates, (err: BusinessError, rows: number) => {
          if (err) {
            console.log(`删除记忆失败${err.message}`)
            reject(err)
            return
          }
          console.log(`删除记忆成功,影响行数${rows}`)
          if (rows > 0) { try { this.notifyChange() } catch (_) {} }
          resolve(rows)
        })
      } catch (callErr) {
        console.log('deleteMemoryById: delete 调用抛出异常', callErr)
        reject(callErr)
      }
    })
  }

  async updateMemoryById(tableName: string, memoryId: number, value: relationalStore.ValuesBucket): Promise<number> {
    console.log('updateMemoryById: waiting for DB ready...')
    await this.readyPromise
    console.log('updateMemoryById: ready, rdbStore is', this.rdbStore ? 'present' : 'null', 'id=', memoryId, 'value=', JSON.stringify(value))
    return new Promise<number>((resolve, reject) => {
      const queryPredicates = new relationalStore.RdbPredicates(tableName)
      // 使用表中真实列名 'id'
      queryPredicates.equalTo('id', memoryId)
      if (!this.rdbStore) {
        console.log('updateMemoryById: rdbStore 为空')
        reject(new Error('rdbStore is null'))
        return
      }
      try {
        this.rdbStore.update(value, queryPredicates, (err: BusinessError, rows: number) => {
          if (err) {
            console.log(`更新记忆失败${err.message}`)
            reject(err)
            return
          }
          console.log(`更新记忆成功,影响行数${rows}`)
          if (rows > 0) { try { this.notifyChange() } catch (_) {} }
          resolve(rows)
        })
      } catch (callErr) {
        console.log('updateMemoryById: update 调用抛出异常', callErr)
        reject(callErr)
      }
    })
  }

  // 兼容性实例方法包装器
  public makeValuesBucket(taskName: string, finished: number, targetDate?: number, content?: string): relationalStore.ValuesBucket {
    return makeValuesBucket(taskName, finished, targetDate, content);
  }

}

// 导出独立帮助器，供其他模块导入，而不依赖类实例形状
interface ValuesBucketMap { task_name?: string; finished?: number; target_date?: number; content?: string }
export function makeValuesBucket(taskName: string, finished: number, targetDate?: number, content?: string): relationalStore.ValuesBucket {
  if (typeof targetDate === 'number') {
    if (typeof content === 'string') {
      return { task_name: taskName, finished: finished, target_date: targetDate, content: content } as relationalStore.ValuesBucket;
    }
    return { task_name: taskName, finished: finished, target_date: targetDate } as relationalStore.ValuesBucket;
  }
  if (typeof content === 'string') {
    return { task_name: taskName, finished: finished, content: content } as relationalStore.ValuesBucket;
  }
  return { task_name: taskName, finished: finished } as relationalStore.ValuesBucket;
}

// 导出单例供其他模块使用
export const MemoryDBUtil = new MemoryDBUtils()

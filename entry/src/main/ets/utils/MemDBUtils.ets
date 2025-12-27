// 数据库工具：RDB 读写与模型映射 / DB helper for RDB operations and mapping
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
  // user-selected date in ms since epoch
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
  // Promise resolved when rdbStore becomes available
  private readyPromise: Promise<void> = Promise.resolve()
  private readyResolve?: () => void
  // (no unused fields)
  // Lightweight change listeners so pages can react to DB changes
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
  //   tabelName: 数据库名称
  initMemoryDB(context: Context, tableName: string) {
    // create a readiness promise that callers can await
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
      target_date integer
    )`

    // (3) 初始化数据库
    relationalStore.getRdbStore(context, STORE_CONFIG, (err, store) => {
      // 获取/创建 RDB / open RDB
      if (err) {
        console.log(`获取taskdb失败, code: ${err.code}, message: ${err.message}`)
        // resolve readiness to avoid deadlocks; operations will still fail due to null rdbStore
        if (this.readyResolve) { this.readyResolve() }
        return
      }

      console.log('创建按rdbStore成功')
      this.rdbStore = store
      // create table then resolve readiness (avoid racing before table exists)
      this.rdbStore.executeSql(SQL_CREATE_TABLE, (err) => {
        if (!err) {
          console.log(`创建${tableName}成功`)
          // signal ready only after table creation
          if (this.readyResolve) { this.readyResolve() }
        } else {
          console.log(`创建${tableName}失败`)
          // still resolve to avoid deadlock; subsequent ops will log rdbStore present but table errors
          if (this.readyResolve) { this.readyResolve() }
        }
      })
      // Attempt to add target_date column if it doesn't exist yet; ignore errors
      try {
        const SQL_ADD_COLUMN = `alter table ${tableName} add column target_date integer`;
        this.rdbStore.executeSql(SQL_ADD_COLUMN, (colErr) => {
          if (!colErr) {
            console.log(`确保 ${tableName}.target_date 列存在: 添加成功`)
          } else {
            console.log(`尝试添加 target_date 列返回: ${colErr.message}`)
          }
        })
      } catch (alterErr) {
        console.log('尝试添加 target_date 列时抛出异常，忽略:', alterErr)
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
          // notify listeners that DB content changed
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
      let p1 = new relationalStore.RdbPredicates(tableName)
      // Return newest first so UI shows recent additions on top
      try { p1.orderByDesc('id') } catch (e) { /* some SDKs may not support orderByDesc */ }
      const resultSet = await (this.rdbStore as relationalStore.RdbStore).query(p1, column)
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

            const memoryId = idIndex >= 0 ? resultSet.getLong(idIndex) : 0
            const title = nameIndex >= 0 ? resultSet.getString(nameIndex) : ''
            const finishedVal = finishedIndex >= 0 ? resultSet.getLong(finishedIndex) : 0
            const targetDateVal = targetDateIndex >= 0 ? resultSet.getLong(targetDateIndex) : undefined

            // 将数据库列映射到 Memory 对象：task_name -> title, target_date -> targetDate
            memories.push(new Memory(memoryId, title, !!finishedVal, undefined, undefined, targetDateVal))
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
      const p1 = new relationalStore.RdbPredicates(tableName)
      // 使用表中真实列名 'id'
      p1.equalTo('id', memoryId)
      if (!this.rdbStore) {
        console.log('deleteMemoryById: rdbStore is null')
        reject(new Error('rdbStore is null'))
        return
      }
      try {
        this.rdbStore.delete(p1, (err: BusinessError, rows: number) => {
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
        console.log('deleteMemoryById: delete call threw', callErr)
        reject(callErr)
      }
    })
  }

  async updateMemoryById(tableName: string, memoryId: number, value: relationalStore.ValuesBucket): Promise<number> {
    console.log('updateMemoryById: waiting for DB ready...')
    await this.readyPromise
    console.log('updateMemoryById: ready, rdbStore is', this.rdbStore ? 'present' : 'null', 'id=', memoryId, 'value=', JSON.stringify(value))
    return new Promise<number>((resolve, reject) => {
      const p1 = new relationalStore.RdbPredicates(tableName)
      // 使用表中真实列名 'id'
      p1.equalTo('id', memoryId)
      if (!this.rdbStore) {
        console.log('updateMemoryById: rdbStore is null')
        reject(new Error('rdbStore is null'))
        return
      }
      try {
        this.rdbStore.update(value, p1, (err: BusinessError, rows: number) => {
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
        console.log('updateMemoryById: update call threw', callErr)
        reject(callErr)
      }
    })
  }

  // Instance method wrapper for compatibility
  public makeValuesBucket(taskName: string, finished: number, targetDate?: number): relationalStore.ValuesBucket {
    return makeValuesBucket(taskName, finished, targetDate);
  }

}

// Export standalone helper for other modules to import without relying on class instance shape
export function makeValuesBucket(taskName: string, finished: number, targetDate?: number): relationalStore.ValuesBucket {
  if (typeof targetDate === 'number') {
    return { task_name: taskName, finished: finished, target_date: targetDate } as relationalStore.ValuesBucket;
  }
  return { task_name: taskName, finished: finished } as relationalStore.ValuesBucket;
}

// 导出单例供其他模块使用
export const MemoryDBUtil = new MemoryDBUtils()

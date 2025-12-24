import { MemoryType, MemoryItem } from '../types/MemoryTypes'
import { MemoryDBUtil } from '../utils/MemDBUtils'
export type { MemoryType, MemoryItem }

const listeners: Array<() => void> = []
let events: MemoryItem[] = [
  { id: 1, title: '生日', date: new Date('2025-06-18'), type: 'anniversary' },
  { id: 2, title: '假期出发', date: new Date('2025-10-01'), type: 'countdown' },
  { id: 3, title: '相识纪念', date: new Date('2024-12-12'), type: 'anniversary' }
]
let selectedId: number | undefined = undefined

function notify(): void {
  for (const cb of listeners) {
    try {
      cb()
    } catch (err) {
      console.log(`listener 调用出错: ${err}`)
    }
  }
}

export default {
  getEvents(): MemoryItem[] {
    return [...events]
  },
  getEventById(id: number): MemoryItem | undefined {
    return events.find((e: MemoryItem) => e.id === id)
  },
  addEvent(item: MemoryItem): void {
    // persist asynchronously, but update UI immediately
    const vb = { task_name: item.title, finished: item.type === 'anniversary' ? 1 : 0 }
    try {
      MemoryDBUtil.insertMemory('memories', vb as any)
        .then((rowId: number) => {
          if (rowId && rowId > 0) item.id = rowId
        })
        .catch((err: Error) => {
          console.log(`DB insert failed: ${err}`)
        })
    } catch (e) {
      // fallback if MemoryDBUtil is not available synchronously
      console.log('MemoryDBUtil.insertMemory threw', e)
    }

    events = [item, ...events]
    notify()
  },
  updateEvent(item: MemoryItem): void {
    const vb = { task_name: item.title, finished: item.type === 'anniversary' ? 1 : 0 }
    try {
      MemoryDBUtil.updateMemoryById('memories', item.id, vb as any)
        .then(() => {})
        .catch((err: Error) => { console.log(`DB update failed: ${err}`) })
    } catch (e) {
      console.log('MemoryDBUtil.updateMemoryById threw', e)
    }

    events = events.map((e: MemoryItem) => (e.id === item.id ? item : e))
    notify()
  },
  deleteEvent(id: number): void {
    try {
      MemoryDBUtil.deleteMemoryById('memories', id)
        .then(() => {})
        .catch((err: Error) => { console.log(`DB delete failed: ${err}`) })
    } catch (e) {
      console.log('MemoryDBUtil.deleteMemoryById threw', e)
    }

    events = events.filter((e: MemoryItem) => e.id !== id)
    if (selectedId === id) selectedId = undefined
    notify()
  },
  setSelected(id?: number): void {
    selectedId = id
  },
  getSelected(): number | undefined {
    return selectedId
  },
  subscribe(cb: () => void): () => void {
    listeners.push(cb)
    return (): void => {
      const idx = listeners.indexOf(cb)
      if (idx >= 0) listeners.splice(idx, 1)
    }
  }
}

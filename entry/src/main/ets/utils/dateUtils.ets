// dateUtils: 通用日期/天数工具，ARKTS 友好写法
export type DateLike = Date | number | string | null | undefined;
export interface EventWithDate {
  date: DateLike;
}

function toDate(input: DateLike): Date | null {
  if (input === null || input === undefined) {
    return null;
  }
  if (input instanceof Date) {
    return isNaN(input.getTime()) ? null : input;
  }
  if (typeof input === 'number') {
    const d: Date = new Date(input);
    return isNaN(d.getTime()) ? null : d;
  }
  if (typeof input === 'string') {
    const d: Date = new Date(input);
    return isNaN(d.getTime()) ? null : d;
  }
  return null;
}

export function formatDate(d: DateLike): string {
  const dt: Date | null = toDate(d);
  if (!dt) {
    return '';
  }
  const y: number = dt.getFullYear();
  const m: string = `${dt.getMonth() + 1}`.padStart(2, '0');
  const day: string = `${dt.getDate()}`.padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export function daysDiff(target: DateLike, now?: DateLike): number {
  const t: Date | null = toDate(target);
  if (!t) {
    return NaN;
  }
  const n: Date = toDate(now) ?? new Date();
  const start: number = new Date(n.getFullYear(), n.getMonth(), n.getDate()).getTime();
  const dest: number = new Date(t.getFullYear(), t.getMonth(), t.getDate()).getTime();
  return Math.round((dest - start) / (24 * 3600 * 1000));
}

export function daysTextFor(target: DateLike, now?: DateLike): string {
  const diff: number = daysDiff(target, now);
  if (isNaN(diff)) {
    return '';
  }
  return diff >= 0 ? `还有 ${diff} 天` : `已过 ${Math.abs(diff)} 天`;
}

export function daysColorFor(target: DateLike, now?: DateLike): string {
  const diff: number = daysDiff(target, now);
  if (isNaN(diff)) {
    return '#666';
  }
  return diff >= 0 ? '#1677FF' : '#FF7A45';
}

export function getEventsSortedByDaysUntil<T extends EventWithDate>(events: T[], now?: DateLike): T[] {
  if (!events || events.length === 0) {
    return [];
  }
  const copy: T[] = [...events];
  copy.sort((a: T, b: T) => {
    const da: number = daysDiff(a.date, now);
    const db: number = daysDiff(b.date, now);
    if (isNaN(da) && isNaN(db)) return 0;
    if (isNaN(da)) return 1;
    if (isNaN(db)) return -1;
    return da - db;
  });
  return copy;
}

export function countUpcoming(events: EventWithDate[], now?: DateLike): number {
  if (!events || events.length === 0) {
    return 0;
  }
  return events.filter((e) => {
    const d: number = daysDiff(e.date, now);
    return !isNaN(d) && d >= 0;
  }).length;
}

export function countMemories(events: EventWithDate[], now?: DateLike): number {
  if (!events || events.length === 0) {
    return 0;
  }
  return events.filter((e) => {
    const d: number = daysDiff(e.date, now);
    return !isNaN(d) && d < 0;
  }).length;
}

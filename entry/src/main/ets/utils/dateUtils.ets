// 日期工具：格式化与天数计算 / Date utilities: formatting & day diffs
// dateUtils: 通用日期/天数工具，ARKTS 友好写法
export type DateLike = Date | number | string | null | undefined;
export interface EventWithDate {
  date: DateLike;
}

// Named class for anniversary stats to satisfy ArkTS lint (no anonymous object literal types)
export class AnniversaryStats {
  daysSince: number;
  daysUntil: number;
  constructor(daysSince: number, daysUntil: number) {
    this.daysSince = daysSince;
    this.daysUntil = daysUntil;
  }
}

// 输入容错转换 / tolerant conversion to Date
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

// normalize to local midnight for day-precision math
function normalizeDate(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

// 日期格式化 / date formatting
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

// 差值主入口 / main diff entry
export function daysDiff(target: DateLike, now?: DateLike, isAnniversary?: boolean): number {
  const t: Date | null = toDate(target);
  if (!t) {
    return NaN;
  }
  const n: Date = normalizeDate(toDate(now) ?? new Date());
  const start: number = n.getTime();
  const dayMs: number = 24 * 3600 * 1000;

  if (!isAnniversary) {
    const dest: number = normalizeDate(t).getTime();
    return Math.floor((dest - start) / dayMs);
  }

  const targetMonth = t.getMonth();
  const targetDay = t.getDate();
  let destDate = new Date(n.getFullYear(), targetMonth, targetDay);
  const destNormalized = normalizeDate(destDate).getTime();
  if (destNormalized < start) {
    destDate = new Date(n.getFullYear() + 1, targetMonth, targetDay);
  }
  const dest = normalizeDate(destDate).getTime();
  return Math.floor((dest - start) / dayMs);
}

// 纪念日：计算已过与下次 / anniversary: days since & until next
export function anniversaryStats(target: DateLike, now?: DateLike): AnniversaryStats {
  const t: Date | null = toDate(target);
  if (!t) {
    return new AnniversaryStats(NaN, NaN);
  }
  const n: Date = normalizeDate(toDate(now) ?? new Date());
  const dayMs = 24 * 3600 * 1000;

  const today = n;
  const origin = normalizeDate(t);
  const targetMonth = origin.getMonth();
  const targetDay = origin.getDate();

  let nextOccur = new Date(today.getFullYear(), targetMonth, targetDay);
  if (nextOccur.getTime() < today.getTime()) {
    nextOccur = new Date(today.getFullYear() + 1, targetMonth, targetDay);
  }

  const daysUntil = Math.floor((normalizeDate(nextOccur).getTime() - today.getTime()) / dayMs);
  const daysSince = Math.floor((today.getTime() - origin.getTime()) / dayMs);
  return new AnniversaryStats(daysSince, daysUntil);
}

// 文本化输出 / stringify stats
export function daysTextFor(target: DateLike, now?: DateLike, isAnniversary?: boolean): string {
  if (isAnniversary) {
    const stats = anniversaryStats(target, now);
    if (isNaN(stats.daysSince) || isNaN(stats.daysUntil)) return '';
    return `${stats.daysUntil}(${stats.daysSince})`;
  }
  const diff: number = daysDiff(target, now, false);
  if (isNaN(diff)) {
    return '';
  }
  return diff >= 0 ? `${diff}` : ` ${Math.abs(diff)} `;
}

// 文本颜色 / color helper
export function daysColorFor(target: DateLike, now?: DateLike, isAnniversary?: boolean): string {
  const diff: number = daysDiff(target, now, isAnniversary);
  if (isNaN(diff)) {
    return '#666';
  }
  return diff >= 0 ? '#1677FF' : '#FF7A45';
}

// 按天数排序 / sort by days until
export function getEventsSortedByDaysUntil<T extends EventWithDate>(events: T[], now?: DateLike, isAnniversaryFor?: (e: T) => boolean): T[] {
  if (!events || events.length === 0) {
    return [];
  }
  const copy: T[] = [...events];
  copy.sort((a: T, b: T) => {
    const da: number = daysDiff(a.date, now, isAnniversaryFor ? !!isAnniversaryFor(a) : false);
    const db: number = daysDiff(b.date, now, isAnniversaryFor ? !!isAnniversaryFor(b) : false);
    if (isNaN(da) && isNaN(db)) return 0;
    if (isNaN(da)) return 1;
    if (isNaN(db)) return -1;
    return da - db;
  });
  return copy;
}

// 未来事件计数 / count upcoming
export function countUpcoming<T extends EventWithDate>(events: T[], now?: DateLike, isAnniversaryFor?: (e: T) => boolean): number {
  if (!events || events.length === 0) {
    return 0;
  }
  return events.filter((e: T) => {
    const d: number = daysDiff(e.date, now, isAnniversaryFor ? !!isAnniversaryFor(e) : false);
    return !isNaN(d) && d >= 0;
  }).length;
}

// 已过事件计数 / count past
export function countMemories<T extends EventWithDate>(events: T[], now?: DateLike, isAnniversaryFor?: (e: T) => boolean): number {
  if (!events || events.length === 0) {
    return 0;
  }
  return events.filter((e: T) => {
    const d: number = daysDiff(e.date, now, isAnniversaryFor ? !!isAnniversaryFor(e) : false);
    return !isNaN(d) && d < 0;
  }).length;
}

// 日期工具：格式化与天数计算 / Date utilities: formatting & day diffs
// 主要职责：日期格式化、天数差值、纪念日统计等
// 详细注释见各函数实现

// 类型定义：支持多种日期输入类型，便于兼容 ArkTS/JS/字符串等
export type DateLike = Date | number | string | null | undefined;
export interface EventWithDate {
  date: DateLike;
}

// 纪念日统计结果类，daysSince: 已过天数，daysUntil: 距下次天数
export class AnniversaryStats {
  daysSince: number;
  daysUntil: number;
  constructor(daysSince: number, daysUntil: number) {
    this.daysSince = daysSince;
    this.daysUntil = daysUntil;
  }
}

/**
 * 输入容错转换，将各种 DateLike 转为 Date 对象，失败返回 null
 * 支持 Date/number/string/null/undefined
 */
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

/**
 * 归一化日期到本地零点，便于天数精度计算
 * @param d Date对象
 * @returns 零点的Date对象
 */
function normalizeDate(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

/**
 * 日期格式化为 yyyy-MM-dd 字符串
 * @param d DateLike 输入
 * @returns 格式化字符串，失败返回空串
 */
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

/**
 * 计算目标日期与当前日期的天数差
 * @param target 目标日期
 * @param now 当前日期（可选，默认今天）
 * @param isAnniversary 是否按纪念日模式（跨年）
 * @returns 天数差，纪念日为距下次周年
 */
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

  // 纪念日模式：计算距下次周年
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

/**
 * 纪念日统计：计算已过天数与距下次周年天数
 * @param target 纪念日日期
 * @param now 当前日期（可选）
 * @returns AnniversaryStats 对象
 */
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

/**
 * 文本化输出天数，纪念日显示“距下次(已过)”，倒数日显示剩余/已过
 * @param target 日期
 * @param now 当前日期
 * @param isAnniversary 是否纪念日
 * @returns 字符串
 */
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

/**
 * 根据天数差返回推荐颜色，未来为蓝色，已过为橙色
 * @param target 日期
 * @param now 当前日期
 * @param isAnniversary 是否纪念日
 * @returns 颜色字符串
 */
export function daysColorFor(target: DateLike, now?: DateLike, isAnniversary?: boolean): string {
  const diff: number = daysDiff(target, now, isAnniversary);
  if (isNaN(diff)) {
    return '#666';
  }
  return diff >= 0 ? '#1677FF' : '#FF7A45';
}

/**
 * 按天数升序排序事件列表，纪念日按周年计算
 * @param events 事件列表
 * @param now 当前日期
 * @param isAnniversaryFor 判断是否纪念日的函数
 * @returns 排序后的事件列表
 */
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

/**
 * 统计未来事件数量（天数>=0）
 * @param events 事件列表
 * @param now 当前日期
 * @param isAnniversaryFor 判断是否纪念日的函数
 * @returns 数量
 */
export function countUpcoming<T extends EventWithDate>(events: T[], now?: DateLike, isAnniversaryFor?: (e: T) => boolean): number {
  if (!events || events.length === 0) {
    return 0;
  }
  return events.filter((e: T) => {
    const d: number = daysDiff(e.date, now, isAnniversaryFor ? !!isAnniversaryFor(e) : false);
    return !isNaN(d) && d >= 0;
  }).length;
}

/**
 * 统计已过事件数量（天数<0）
 * @param events 事件列表
 * @param now 当前日期
 * @param isAnniversaryFor 判断是否纪念日的函数
 * @returns 数量
 */
export function countMemories<T extends EventWithDate>(events: T[], now?: DateLike, isAnniversaryFor?: (e: T) => boolean): number {
  if (!events || events.length === 0) {
    return 0;
  }
  return events.filter((e: T) => {
    const d: number = daysDiff(e.date, now, isAnniversaryFor ? !!isAnniversaryFor(e) : false);
    return !isNaN(d) && d < 0;
  }).length;
}

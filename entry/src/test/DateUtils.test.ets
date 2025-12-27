import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import * as dateUtils from '../main/ets/utils/dateUtils';

export default function dateUtilsTest() {
  describe('dateUtilsTest', () => {

    // Test daysDiff for regular countdown dates
    it('daysDiff should calculate regular countdown dates correctly', 0, () => {
      const now = new Date(2025, 11, 27); // 2025-12-27

      // Test 1: Future date
      const futureDate = new Date(2026, 0, 15); // 2026-01-15
      const daysDiff1 = dateUtils.daysDiff(futureDate, now, false);
      expect(daysDiff1).assertEqual(19); // 19 days until 2026-01-15

      // Test 2: Past date
      const pastDate = new Date(2025, 0, 15); // 2025-01-15
      const daysDiff2 = dateUtils.daysDiff(pastDate, now, false);
      expect(daysDiff2).assertEqual(-346); // 346 days ago

      // Test 3: Today
      const today = new Date(2025, 11, 27); // 2025-12-27
      const daysDiff3 = dateUtils.daysDiff(today, now, false);
      expect(daysDiff3).assertEqual(0); // Today is 0 days away
    });

    // Test daysDiff for anniversary dates
    it('daysDiff should calculate anniversary dates correctly', 0, () => {
      const now = new Date(2025, 11, 27); // 2025-12-27

      // Test 1: Anniversary that hasn't occurred this year yet (future)
      const anniversary1 = new Date(2025, 0, 15); // Jan 15 (already passed in 2025)
      const daysDiff1 = dateUtils.daysDiff(anniversary1, now, true);
      expect(daysDiff1).assertEqual(19); // Days until next Jan 15 (2026-01-15)

      // Test 2: Anniversary that has already occurred this year
      const anniversary2 = new Date(2025, 0, 15); // Jan 15 (already passed)
      const daysDiff2 = dateUtils.daysDiff(anniversary2, now, true);
      expect(daysDiff2).assertEqual(19); // Days until next Jan 15

      // Test 3: Anniversary coming up this year
      const anniversary3 = new Date(2025, 11, 31); // Dec 31 (4 days away)
      const daysDiff3 = dateUtils.daysDiff(anniversary3, now, true);
      expect(daysDiff3).assertEqual(4); // 4 days until Dec 31

      // Test 4: Today is the anniversary
      const anniversary4 = new Date(2025, 11, 27); // Dec 27 (today)
      const daysDiff4 = dateUtils.daysDiff(anniversary4, now, true);
      expect(daysDiff4).assertEqual(365); // 365 days until next Dec 27
    });

    // Test anniversaryStats
    it('anniversaryStats should calculate days since and until correctly', 0, () => {
      const now = new Date(2025, 11, 27); // 2025-12-27

      // Test with a past anniversary (Jan 15)
      const pastAnniversary = new Date(2025, 0, 15); // Jan 15
      const stats1 = dateUtils.anniversaryStats(pastAnniversary, now);
      expect(stats1.daysUntil).assertEqual(19); // Days until next Jan 15
      expect(stats1.daysSince).assertEqual(346); // Days since last Jan 15 (2025-01-15)

      // Test with anniversary today (Dec 27)
      const todayAnniversary = new Date(2025, 11, 27); // Dec 27
      const stats2 = dateUtils.anniversaryStats(todayAnniversary, now);
      expect(stats2.daysUntil).assertEqual(365); // Days until next Dec 27
      expect(stats2.daysSince).assertEqual(0); // Days since this Dec 27 (today)
    });

    // Test daysTextFor for anniversaries
    it('daysTextFor should format anniversary text correctly', 0, () => {
      const now = new Date(2025, 11, 27); // 2025-12-27

      // Test with a past anniversary (Jan 15)
      const pastAnniversary = new Date(2025, 0, 15); // Jan 15
      const text1 = dateUtils.daysTextFor(pastAnniversary, now, true);
      expect(text1).assertEqual('19(346)'); // daysUntil(daysSince)
    });
  });
}


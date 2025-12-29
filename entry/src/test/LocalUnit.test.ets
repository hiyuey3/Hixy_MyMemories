import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';

export default function localUnitTest() {
  describe('localUnitTest', () => {
    // 定义一个测试套件。支持两个参数：测试套件名称和测试套件函数。
    beforeAll(() => {
      // 预设一个操作，在测试套件的所有测试用例开始前仅执行一次。
      // 此API仅支持一个参数：预设操作函数。
    });
    beforeEach(() => {
      // 预设一个操作，在每个单元测试用例开始前执行。
      // 执行次数与由**it**定义的测试用例数量相同。
      // 此API仅支持一个参数：预设操作函数。
    });
    afterEach(() => {
      // 预设一个清理操作，在每个单元测试用例结束后执行。
      // 执行次数与由**it**定义的测试用例数量相同。
      // 此API仅支持一个参数：清理操作函数。
    });
    afterAll(() => {
      // 预设一个清理操作，在测试套件的所有测试用例结束后执行。
      // 此API仅支持一个参数：清理操作函数。
    });
    it('assertContain', 0, () => {
      // 定义一个测试用例。此API支持三个参数：测试用例名称、过滤参数和测试用例函数。
      let a = 'abc';
      let b = 'b';
      // 定义多种断言方法，用于声明预期的布尔条件。
      expect(a).assertContain(b);
      expect(a).assertEqual(a);
    });
  });
}
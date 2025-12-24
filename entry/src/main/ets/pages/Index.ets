import { Settings } from './Settings';
import MemoryStore from '../store/MemoryStore';
import router from '@system.router';
import { About } from './About';
import { MemoryItem } from '../types/MemoryTypes';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import preferences from '@ohos.data.preferences';
import image from '@ohos.multimedia.image';
import util from '@ohos.util';
import common from '@ohos.app.ability.common';


@Entry
@Component
struct Index {
  // Use store as the single source of truth for events
  @State events: MemoryItem[] = MemoryStore.getEvents();
  @State currentIndex: number = 0;
  // Persisted header image uri
  @State headerImagePath: string = '';
  @State headerImageBase64: string = '';
  private tabsController: TabsController = new TabsController();

  onInit(): void {
    // Keep the list in sync when other pages update the store
    MemoryStore.subscribe(() => {
      this.events = MemoryStore.getEvents();
    });
    // Load persisted header image
    this.loadHeaderImage();
    this.loadHeaderImageBase64();
  }

  // Removed saveHeaderImage because we now persist the base64 thumbnail instead

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End, controller: this.tabsController, index: this.currentIndex }) {
        // Home tab
        TabContent() {
          Column({ space: 12 }) {
            Column() {
              // Single Image with dynamic source (shown as circle via borderRadius)
              Image(this.imageSource())
                .id('headerImage')
                .width(150)
                .height(150)
                .objectFit(ImageFit.Cover)
                .borderRadius(75)
                .align(Alignment.Center)
                .onClick(() => {
                  this.pickHeaderImage();
                });
            }
            .height('160px')
            .width('100%')
            .padding({ top: 18 });

            Column({ space: 8 }) {
              Text('倒数日 & 纪念日').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#1F1F1F');
              Row({ space: 12 }) {
                Column() {
                  Text(`${this.getUpcoming()}`).fontSize(28).fontWeight(FontWeight.Bold).fontColor('#1677FF');
                  Text('即将到来').fontSize(13).fontColor('#666');
                }
                .padding(12)
                .backgroundColor('#F2F6FF')
                .borderRadius(12);

                Column() {
                  Text(`${this.getMemories()}`).fontSize(28).fontWeight(FontWeight.Bold).fontColor('#FF7A45');
                  Text('纪念回顾').fontSize(13).fontColor('#666');
                }
                .padding(12)
                .backgroundColor('#FFF4EC')
                .borderRadius(12);
              }
            }
            .padding({
              left: 18,
              right: 18,
              top: 20,
              bottom: 12
            });

            List({ space: 10 }) {
              ForEach(this.sorted(), (item: MemoryItem) => {
                ListItem() {
                  this.EventCard(item);
                }
              })
            }
            .edgeEffect(EdgeEffect.None)
            .width('100%')
            .height('100%')
            .layoutWeight(1)
            .padding({ left: 18, right: 18, bottom: 10 });

            Row() {
              Button('+ 新增事件')
                .type(ButtonType.Capsule)
                .backgroundColor(Color.Pink)
                .fontColor('#fff')
                .width('70%')
                .height(39)
                .onClick(() => {
                  try {
                    router.push({ uri: 'pages/AddMemory' });
                  } catch (e) {
                    console.error(e);
                  }
                });
            }
            .justifyContent(FlexAlign.Center)
            .padding({ bottom: 10 });

          }
          .width('100%')
          .height('100%')
          .backgroundColor('#F7F8FA');
        }
        .tabBar(this.TabBuilder('首页', 0));

        // Memories tab
        TabContent() {
          Column({ space: 12 }) {
            List({ space: 10 }) {
              ForEach(this.sorted(), (item: MemoryItem) => {
                ListItem() {
                  Column() {
                    this.EventCard(item);
                  }
                  .onClick(() => {
                    MemoryStore.setSelected(item.id);
                    try {
                      router.push({ uri: 'pages/EventDetail' });
                    } catch (e) {
                      console.error(e);
                    }
                  });
                }
              })
            }
            .edgeEffect(EdgeEffect.None)
            .width('100%')
            .height('100%')
            .layoutWeight(1)
            .padding({ left: 18, right: 18, bottom: 18 });
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#F7F8FA');
        }
        .tabBar(this.TabBuilder('记忆', 1, $r('app.media.foreground')));

        // Settings tab
        TabContent() {
          Settings()
        }
        .tabBar(this.TabBuilder('设置', 2, $r('app.media.foreground')));

        // About tab
        TabContent() {
          About()
        }
        .tabBar(this.TabBuilder('关于', 3, $r('app.media.foreground')));

      }
      .width('100%')
      .height('100%')
      .scrollable(false)
      .backgroundColor(Color.Pink)
      .animationDuration(0);

    }
    .width('100%')
    .height('100%');
  }

  private loadHeaderImage(): void {
    const stored = AppStorage.Get<string>('headerImagePath');
    this.headerImagePath = stored ?? '';
  }

  private async saveHeaderImageBase64(base64: string): Promise<void> {
    this.headerImageBase64 = base64;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const pref = await preferences.getPreferences(context, 'user_prefs');
      await pref.put('headerImageBase64', base64);
      await pref.flush();
    } catch (e) {
      console.error('saveHeaderImageBase64 error', e);
    }
  }

  private async loadHeaderImageBase64(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const pref = await preferences.getPreferences(context, 'user_prefs');
      const val = await pref.get('headerImageBase64', '');
      this.headerImageBase64 = typeof val === 'string' ? val : '';
    } catch (e) {
      console.error('loadHeaderImageBase64 error', e);
    }
  }

  private async toBase64FromPixelMap(data: image.PixelMap): Promise<string> {
    let imagePackerApi: image.ImagePacker = image.createImagePacker();
    let packOpts: image.PackingOption = { format: 'image/png', quality: 100 };
    try {
      const readBuffer: ArrayBuffer = await imagePackerApi.packToData(data, packOpts);
      const bufferArr = new Uint8Array(readBuffer);
      const help = new util.Base64Helper();
      return help.encodeToStringSync(bufferArr);
    } catch (err) {
      console.error('packToData error', err);
      return '';
    }
  }

  private async pickHeaderImage(): Promise<void> {
    try {
      const photoSelectOptions: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      const photoViewPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const uris: photoAccessHelper.PhotoSelectResult = await photoViewPicker.select(photoSelectOptions);
      if (!uris || !uris.photoUris || uris.photoUris.length === 0) {
        return;
      }
      const srcUri: string = uris.photoUris[0];

      // Load PixelMap from selected uri
      const imgSource = image.createImageSource(srcUri);
      const pixelMap: image.PixelMap = await imgSource.createPixelMap();
      // Convert to base64 and persist
      const base64 = await this.toBase64FromPixelMap(pixelMap);
      if (base64 && base64.length > 0) {
        await this.saveHeaderImageBase64(base64);
      }
    } catch (e) {
      console.error('pickHeaderImage error', e);
    }
  }

  private imageSource(): string | Resource {
    if (this.headerImageBase64 && this.headerImageBase64.length > 0) {
      return 'data:image/png;base64,' + this.headerImageBase64;
    }
    if (this.headerImagePath && this.headerImagePath.length > 0) {
      return this.headerImagePath;
    }
    return $r('app.media.background');
  }

  private formatDate(d: Date): string {
    const y = d.getFullYear();
    const m = `${d.getMonth() + 1}`.padStart(2, '0');
    const day = `${d.getDate()}`.padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  private daysDiff(target: Date): number {
    const today = new Date();
    const start = new Date(today.getFullYear(), today.getMonth(), today.getDate()).getTime();
    const dest = new Date(target.getFullYear(), target.getMonth(), target.getDate()).getTime();
    return Math.round((dest - start) / (24 * 3600 * 1000));
  }

  private getEventsSortedByDaysUntil(): MemoryItem[] {
    return [...this.events].sort((a, b) => this.daysDiff(a.date) - this.daysDiff(b.date));
  }

  private sorted(): MemoryItem[] {
    return this.getEventsSortedByDaysUntil();
  }

  private getUpcoming(): number {
    return this.events.filter(i => this.daysDiff(i.date) >= 0).length;
  }

  private getMemories(): number {
    return this.events.filter(i => this.daysDiff(i.date) < 0).length;
  }

  @Builder
  private EventCard(item: MemoryItem): void {
    Row({ space: 8 }) {
      Column({ space: 6 }) {
        Text(item.title).fontSize(18).fontWeight(FontWeight.Medium).fontColor('#111');
        Text(this.formatDate(item.date)).fontSize(13).fontColor('#666');
        Text(this.daysDiff(item.date) >= 0 ? `还有 ${this.daysDiff(item.date)} 天` :
          `已过 ${Math.abs(this.daysDiff(item.date))} 天`)
          .fontSize(14)
          .fontColor(this.daysDiff(item.date) >= 0 ? '#1677FF' : '#FF7A45');
      }

      Text(item.type === 'countdown' ? '倒数' : '纪念')
        .fontSize(12)
        .fontColor('#fff')
        .padding({
          left: 10,
          right: 10,
          top: 4,
          bottom: 4
        })
        .backgroundColor(item.type === 'countdown' ? '#1677FF' : '#FF7A45')
        .borderRadius(12);
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .padding(14)
    .backgroundColor($r('app.color.start_window_background'))
    .borderRadius(14)
    .width('100%')
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 4
    });
  }

  @Builder
  private TabBuilder(title: string, targetIndex: number, normalImg?: Resource, selectedImg?: Resource) {
    Column() {
      Image(normalImg ? (this.currentIndex == targetIndex ? selectedImg ?? normalImg : normalImg) :
        $r('app.media.startIcon'))
        .width(24)
        .height(24)
        .align(Alignment.Center);
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex == targetIndex ? '#ff4116ff' : '#333')
        .align(Alignment.Center)
        .margin({ top: 6 });
    }
    .width('100%')
    .height(64)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
      try {
        this.tabsController.changeIndex(this.currentIndex);
      } catch (e) {
        console.error(e);
      }
    });
  }
}
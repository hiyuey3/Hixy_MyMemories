import router from '@system.router';
import { MemoryItem } from '../types/MemoryTypes';
import { HomePage } from '../pages/HomePage';
import { MemoriesPage } from '../pages/MemoriesPage';
import { About } from '../pages/About';
import { BottomTabItem } from './BottomTabItem';

export interface IndexTabsProps {
  events: MemoryItem[];
  sortedEvents: MemoryItem[];
  currentIndex: number;
  onTabChange: (idx: number) => void;
  onAdd: () => void;
  onReloadHome: () => void;
  imageSource?: string | Resource;
}

@Builder
export function IndexTabs(props: IndexTabsProps) {
  Tabs({ barPosition: BarPosition.End, controller: new TabsController(), index: props.currentIndex }) {
    // Home tab
    TabContent() {
      HomePage({
        events: props.events,
        imageSource: props.imageSource ?? $r('app.media.hixy_logo_new'),
        onAdd: () => props.onAdd(),
        onManage: () => { router.push({ uri: 'pages/ManageMemories' }); }
      });
    }
    .tabBar(BottomTabItem({
      title: '首页',
      targetIndex: 0,
      currentIndex: props.currentIndex,
      normalImg: $r('app.media.tab_home'),
      selectedImg: $r('app.media.tab_home_active'),
      onSelect: (idx: number) => {
        props.onTabChange(idx);
        // changeIndex handled by Tabs controller ref in props if needed
        if (idx === 0) {
          props.onReloadHome();
        }
      }
    }));

    // Memories tab
    TabContent() {
      MemoriesPage({ events: props.sortedEvents })
    }
    .tabBar(BottomTabItem({
      title: '记忆',
      targetIndex: 1,
      currentIndex: props.currentIndex,
      normalImg: $r('app.media.tab_memories'),
      selectedImg: $r('app.media.tab_memories_active'),
      onSelect: (idx: number) => {
        props.onTabChange(idx);
        // changeIndex handled by Tabs controller ref in props if needed
      }
    }));

    // About tab
    TabContent() {
      About()
    }
    .tabBar(BottomTabItem({
      title: '关于',
      targetIndex: 2,
      currentIndex: props.currentIndex,
      normalImg: $r('app.media.tab_about'),
      selectedImg: $r('app.media.tab_about_active'),
      onSelect: (idx: number) => {
        props.onTabChange(idx);
        // changeIndex handled by Tabs controller ref in props if needed
      }
    }));
  }
  .width('100%')
  .height('100%')
  .scrollable(false)
  .backgroundColor('#F7F8FA')
  .animationDuration(0);
}

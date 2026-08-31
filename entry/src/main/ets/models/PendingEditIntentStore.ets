import { PendingEditIntent } from './EditModels';

/**
 * 登录门禁使用的单条进程内待续意图。
 *
 * 不持久化、不记录 URI；所有读写均复制对象，避免调用方持有内部引用。
 */
export class PendingEditIntentStore {
  private static current: PendingEditIntent | undefined = undefined;

  public static set(intent: PendingEditIntent): void {
    PendingEditIntentStore.current = PendingEditIntentStore.copy(intent);
  }

  public static peek(): PendingEditIntent | undefined {
    const intent = PendingEditIntentStore.current;
    return intent === undefined ? undefined : PendingEditIntentStore.copy(intent);
  }

  public static consume(): PendingEditIntent | undefined {
    const intent = PendingEditIntentStore.current;
    PendingEditIntentStore.current = undefined;
    return intent === undefined ? undefined : PendingEditIntentStore.copy(intent);
  }

  public static clear(): void {
    PendingEditIntentStore.current = undefined;
  }

  private static copy(intent: PendingEditIntent): PendingEditIntent {
    return {
      imageUri: intent.imageUri,
      displayUri: intent.displayUri,
      initialTool: intent.initialTool,
      createdAt: intent.createdAt
    };
  }
}

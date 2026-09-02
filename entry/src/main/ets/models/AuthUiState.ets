/**
 * 认证相关页面的 UI 刷新信号。
 *
 * MockAuthStore 只负责账户业务；页面在业务操作成功后调用本类通知
 * @StorageProp('authRevision') 重新读取最新会话投影。
 */
export class AuthUiState {
  private static revision: number = 0;

  public static bumpRevision(): void {
    AuthUiState.revision += 1;
    AppStorage.setOrCreate('authRevision', AuthUiState.revision);
  }
}

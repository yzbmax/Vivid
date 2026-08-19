import localUnitTest from './LocalUnit.test';
import authValidatorsTest from './AuthValidators.test';
import mockAuthStoreTest from './MockAuthStore.test';
import mockWorkStoreTest from './MockWorkStore.test';
import editModelsTest from './EditModels.test';
import appSettingsStoreTest from './AppSettingsStore.test';

export default function testsuite() {
  localUnitTest();
  authValidatorsTest();
  mockAuthStoreTest();
  mockWorkStoreTest();
  editModelsTest();
  appSettingsStoreTest();
}

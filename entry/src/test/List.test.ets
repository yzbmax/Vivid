import localUnitTest from './LocalUnit.test';
import authValidatorsTest from './AuthValidators.test';
import mockAuthStoreTest from './MockAuthStore.test';

export default function testsuite() {
  localUnitTest();
  authValidatorsTest();
  mockAuthStoreTest();
}

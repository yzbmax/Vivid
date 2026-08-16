import localUnitTest from './LocalUnit.test';
import authValidatorsTest from './AuthValidators.test';

export default function testsuite() {
  localUnitTest();
  authValidatorsTest();
}

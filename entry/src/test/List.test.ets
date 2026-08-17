import localUnitTest from './LocalUnit.test';
import authValidatorsTest from './AuthValidators.test';
import editModelsTest from './EditModels.test';

export default function testsuite() {
  localUnitTest();
  authValidatorsTest();
  editModelsTest();
}

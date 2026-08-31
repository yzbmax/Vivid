import localUnitTest from './LocalUnit.test';
import authValidatorsTest from './AuthValidators.test';
import mockAuthStoreTest from './MockAuthStore.test';
import mockWorkStoreTest from './MockWorkStore.test';
import editModelsTest from './EditModels.test';
import appSettingsStoreTest from './AppSettingsStore.test';
import filterStateTest from './FilterState.test';
import previewPipelineTest from './PreviewPipeline.test';
import thumbnailPipelineTest from './ThumbnailPipeline.test';
import photoPickerServiceTest from './PhotoPickerService.test';

export default function testsuite() {
  localUnitTest();
  authValidatorsTest();
  mockAuthStoreTest();
  mockWorkStoreTest();
  editModelsTest();
  appSettingsStoreTest();
  filterStateTest();
  previewPipelineTest();
  thumbnailPipelineTest();
  photoPickerServiceTest();
}

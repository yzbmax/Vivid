import localUnitTest from './LocalUnit.test';
import authValidatorsTest from './AuthValidators.test';
import mockAuthStoreTest from './MockAuthStore.test';
import mockWorkStoreTest from './MockWorkStore.test';
import editModelsTest from './EditModels.test';
import sharedContractsTest from './SharedContracts.test';
import borderStateTest from './BorderState.test';
import appSettingsStoreTest from './AppSettingsStore.test';
import editPageFixesTest from './EditPageFixes.test';
import maskProcessorTest from './MaskProcessor.test';
import maskDataUtilsTest from './MaskDataUtils.test';
import filterStateTest from './FilterState.test';
import previewPipelineTest from './PreviewPipeline.test';
import thumbnailPipelineTest from './ThumbnailPipeline.test';
import photoPickerServiceTest from './PhotoPickerService.test';
import editorSnapshotTest from './EditorSnapshot.test';
import editorCompositionModelsTest from './EditorCompositionModels.test';

export default function testsuite() {
  localUnitTest();
  authValidatorsTest();
  mockAuthStoreTest();
  mockWorkStoreTest();
  editModelsTest();
  sharedContractsTest();
  borderStateTest();
  appSettingsStoreTest();
  editPageFixesTest();
  maskProcessorTest();
  maskDataUtilsTest();
  filterStateTest();
  previewPipelineTest();
  thumbnailPipelineTest();
  photoPickerServiceTest();
  editorSnapshotTest();
  editorCompositionModelsTest();
}

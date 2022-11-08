import React, {FC, useEffect, useState} from 'react';
import {View} from 'react-native';
import * as CloudStore from 'react-native-cloud-store';
import { PathUtils, defaultICloudContainerPath } from 'react-native-cloud-store';
import * as RNFS from 'react-native-fs';
import {KeyboardAwareScrollView} from 'react-native-keyboard-aware-scroll-view';
import Input from '../components/input';
import Block from '../components/Block';
import Button from '../components/Button';

interface Props {}

const IOSICloudScreen: FC<Props> = ({}) => {
  const [dirForReadOnly, setDirForReadOnly] = useState(
    PathUtils.join(defaultICloudContainerPath, 'Documents'),
  );
  const [dirForCreate, setDirForCreate] = useState(
    PathUtils.join(defaultICloudContainerPath, '/Documents/test-create'),
  );

  const [dirForMoveFrom, setDirForMoveFrom] = useState('');
  const [dirForMoveDest, setDirForMoveDest] = useState('');

  const [filePathForWrite, setFilePathForWrite] = useState(
    PathUtils.join(defaultICloudContainerPath, 'Documents/test-create/demo.tx'),
  );
  const [fileContentForWrite, setFileContentForWrite] = useState('some text');

  const [fileForReadOnly, setFileForReadOnly] = useState(
    PathUtils.join(defaultICloudContainerPath, 'Documents/test-create/demo.tx'),
  );

  const [fileForDownload, setFileForDownload] = useState(
    PathUtils.join(defaultICloudContainerPath, 'Documents/file-on-cloud.txt'),
  );
  const [fileForStore, setFileForStore] = useState(
    RNFS.DocumentDirectoryPath + '/',
  );

  const [localFilePathForWrite, setLocalFilePathForWrite] = useState(
    RNFS.DocumentDirectoryPath + '/local-file.txt',
  );
  const [localFileContentForWrite, setLocalFileContentForWrite] = useState(
    'file content to write',
  );

  const [fileForUpload, setFileForUpload] = useState(localFilePathForWrite);
  const [fileUploadedTo, setFileUploadedTo] = useState(
    CloudStore.defaultICloudContainerPath +
      '/Documents/file-uploaded-from-local.txt',
  );

  const [localFilePathForDelete, setlLocalFilePathForDelete] = useState(
    RNFS.DocumentDirectoryPath + '/local-file.txt',
  );

  useEffect(() => {
    const r1 = CloudStore.onICloudIdentityDidChange(u => {
      console.log(`onICloudIdentityDidChange:`, u);
    });

    const r2 = CloudStore.onICloudDocumentsStartGathering(u => {
      console.log(`onICloudDocumentsStartGathering:`, u);
    });

    const r3 = CloudStore.onICloudDocumentsGathering(u => {
      console.log(`onICloudDocumentsGathering:`, u);
    });

    const r4 = CloudStore.onICloudDocumentsFinishGathering(u => {
      console.log(`onICloudDocumentsFinishGathering:`, u);
    });

    const r5 = CloudStore.onICloudDocumentsUpdateGathering(u => {
      console.log(`onICloudDocumentsUpdateGathering:`, u);
    });

    return () => {
      r1.remove();
      r2.remove();
      r3.remove();
      r4.remove();
      r5.remove();
    };
  }, []);

  return (
    <KeyboardAwareScrollView
      style={{flex: 1}}
      contentContainerStyle={{
        paddingBottom: 50,
      }}>
      <Block>
        <Button
          title={'isICloudAvailable'}
          onPress={async () => {
            try {
              const available = await CloudStore.isICloudAvailable();
              console.log('isICloudAvailable:', available);
            } catch (e) {
              console.error(e);
            }
          }}
        />
        <Button
          title={'get default icloud path'}
          onPress={() => {
            console.log(
              'default icloud path:',
              CloudStore.defaultICloudContainerPath,
            );
          }}
        />
        <Button
          title={'getICloudURL'}
          onPress={async () => {
            try {
              const getICloudURL = await CloudStore.getICloudURL();
              console.log('getICloudURL:', getICloudURL);
            } catch (e) {
              console.error(e);
            }
          }}
        />
        <Button
          title={'getICloudURL with custom id'}
          onPress={async () => {
            try {
              // apple doc said you need pass TEAMEID, actually you should not!
              const getICloudURL = await CloudStore.getICloudURL(
                'iCloud.org.reactjs.native.example.RNCloudStoreTestAPP',
              );
              console.log('getICloudURL with custom id:', getICloudURL);
            } catch (e) {
              console.error(e);
            }
          }}
        />
      </Block>

      <Block>
        <Input
          value={dirForReadOnly}
          onChangeText={setDirForReadOnly}
          placeholder={'icloud dir (relative) path'}
        />
        <View style={{flexDirection: 'row', justifyContent: 'space-between'}}>
          <Button
            title={'stat dir'}
            onPress={async () => {
              try {
                const val = await CloudStore.stat(dirForReadOnly);
                console.log(
                  `stat of "${dirForReadOnly}":\n`,
                  JSON.stringify(val, null, 2),
                );
              } catch (e) {
                console.error(e);
              }
            }}
          />
          <Button
            title={'read dir'}
            onPress={async () => {
              try {
                const dirs = await CloudStore.readDir(dirForReadOnly);
                console.log(
                  `[dirs of "${dirForReadOnly}"]:\n`,
                  dirs.join('\n'),
                );
              } catch (e) {
                console.error(e);
              }
            }}
          />
        </View>
      </Block>

      <Block>
        <Input
          value={dirForCreate}
          onChangeText={setDirForCreate}
          placeholder={'dir relative path'}
        />
        <Button
          title={'create dir'}
          onPress={async () => {
            try {
              await CloudStore.createDir(dirForCreate);
              console.log(`created dir "${dirForCreate}"`);
            } catch (e) {
              console.error(e);
            }
          }}
        />
      </Block>

      <Block>
        <Input
          value={dirForMoveFrom}
          onChangeText={setDirForMoveFrom}
          placeholder={'from dir path'}
        />
        <Input
          value={dirForMoveDest}
          onChangeText={setDirForMoveDest}
          placeholder={'to dir path'}
        />
        <Button
          title={'move dir'}
          onPress={async () => {
            try {
              await CloudStore.moveDir(dirForMoveFrom, dirForMoveDest);
              console.log(
                `moved from "${dirForMoveFrom}" to "${dirForMoveDest}"`,
              );
            } catch (e) {
              console.error(e);
            }
          }}
        />
      </Block>

      <Block>
        <Input
          value={filePathForWrite}
          onChangeText={setFilePathForWrite}
          placeholder={'file path'}
        />
        <Input
          value={fileContentForWrite}
          onChangeText={setFileContentForWrite}
          placeholder={'file content'}
        />

        <Button
          title={'write file'}
          onPress={async () => {
            try {
              await CloudStore.writeFile(filePathForWrite, fileContentForWrite);
              console.log('wrote file');
            } catch (e) {
              console.error(e);
            }
          }}
        />
      </Block>

      <Block>
        <Input
          value={fileForReadOnly}
          onChangeText={setFileForReadOnly}
          placeholder={'file path'}
        />
        <View style={{flexDirection: 'row', justifyContent: 'space-between'}}>
          <Button
            title={'stat file'}
            onPress={async () => {
              try {
                const val = await CloudStore.stat(fileForReadOnly);
                console.log(`stat of "${fileForReadOnly}":\n`, val);
              } catch (e) {
                console.error(e);
              }
            }}
          />

          <Button
            title={'read file'}
            onPress={async () => {
              try {
                const val = await CloudStore.readFile(fileForReadOnly);
                console.log(`read file of "${fileForReadOnly}":\n`, val);
              } catch (e) {
                console.error(e);
              }
            }}
          />
        </View>
        <View style={{flexDirection: 'row', justifyContent: 'space-between'}}>
          <Button
            title={'remove file'}
            onPress={async () => {
              try {
                await CloudStore.unlink(fileForReadOnly);
                console.log(`removed file of "${fileForReadOnly}"`);
              } catch (e) {
                console.error(e);
              }
            }}
          />
          <Button
            title={'file exists'}
            onPress={async () => {
              try {
                const val = await CloudStore.exist(fileForReadOnly);
                console.log(`file "${fileForReadOnly}" exists:`, val);
              } catch (e) {
                console.error(e);
              }
            }}
          />
        </View>
      </Block>

      <Block>
        <Input
          value={fileForDownload}
          onChangeText={setFileForDownload}
          placeholder={'file path'}
        />
        <Button
          title={'download'}
          onPress={async () => {
            try {
              await CloudStore.download(fileForDownload);
              console.log('download called');
            } catch (e) {
              console.error(e);
            }
          }}
        />

        <Input
          value={fileForStore}
          onChangeText={setFileForStore}
          placeholder={'local file path'}
        />
        <Button
          title={'copy downloaded file to local'}
          onPress={async () => {
            try {
              await RNFS.copyFile(fileForDownload, fileForStore);
              console.log('coped from icloud to local');
            } catch (e) {
              console.error(e);
            }
          }}
        />
      </Block>

      <View style={{height: 1, borderWidth: 1, borderColor: 'gray'}} />

      <Block>
        <Button
          title={'list local documents folder files'}
          onPress={() => {
            RNFS.readDir(RNFS.DocumentDirectoryPath)
              .then(success => {
                console.log(success);
              })
              .catch(err => {
                console.error('read local dir error:', err.message);
              });
          }}
        />
      </Block>

      <Block>
        <Input
          value={localFilePathForWrite}
          onChangeText={setLocalFilePathForWrite}
          placeholder={'local file path'}
        />
        <Input
          value={localFileContentForWrite}
          onChangeText={setLocalFileContentForWrite}
          placeholder={'file content to write'}
        />
        <Button
          title={'write to local file'}
          onPress={() => {
            RNFS.writeFile(
              localFilePathForWrite,
              localFileContentForWrite,
              'utf8',
            )
              .then(_success => {
                console.log('file written to local');
              })
              .catch(err => {
                console.error('file write to local error:', err.message);
              });
          }}
        />
      </Block>

      <Block>
        <Input
          value={fileForUpload}
          onChangeText={setFileForUpload}
          placeholder={'local file full path with or without schema'}
        />
        <Input
          value={fileUploadedTo}
          onChangeText={setFileUploadedTo}
          placeholder={'icloud file path'}
        />
        <Button
          title={'upload local file to icloud'}
          onPress={async () => {
            try {
              console.log(
                `will upload "${fileForUpload}" to icloud "${fileUploadedTo}"`,
              );
              await CloudStore.upload(fileForUpload, fileUploadedTo);
              console.log('upload called');
            } catch (e) {
              console.error('upload error:', e);
            }
          }}
        />
      </Block>

      <Block>
        <Input
          value={localFilePathForDelete}
          onChangeText={setlLocalFilePathForDelete}
          placeholder={'file path'}
        />
        <Button
          title={'delete local file'}
          onPress={() => {
            RNFS.unlink(localFilePathForDelete)
              .then(() => {
                console.log('deleted');
              })
              .catch(err => {
                console.error('delete error:', err.message);
              });
          }}
        />
      </Block>
    </KeyboardAwareScrollView>
  );
};

export default IOSICloudScreen;

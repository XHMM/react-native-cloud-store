import React, {FC, useEffect, useState} from 'react';
import {KeyboardAvoidingView, Platform, ScrollView, View} from 'react-native';
import * as CloudStore from 'react-native-cloud-store';
import {PathUtils, defaultICloudContainerPath} from 'react-native-cloud-store';
import * as RNFS from 'react-native-fs';
import Input from '../components/input';
import Block from '../components/Block';
import Button from '../components/Button';
import {DirReader} from 'react-native-dir-viewer';
import {Dirs} from 'react-native-file-access';

interface Props {}

const IOSICloudScreen: FC<Props> = ({}) => {
  useEffect(() => {
    const r1 = CloudStore.registerICloudIdentityDidChangeEvent();
    const r2 = CloudStore.registerGlobalDownloadEvent();
    const r3 = CloudStore.registerGlobalUploadEvent();

    return () => {
      r1?.remove();
      r2?.remove();
      r3?.remove();
    };
  }, []);

  useEffect(() => {
    const e1 = CloudStore.onICloudIdentityDidChange(u => {
      console.log(`onICloudIdentityDidChange:`, u);
    });

    const e2 = CloudStore.onICloudDocumentsStartGathering(u => {
      console.log(`onICloudDocumentsStartGathering:`, u);
    });

    const e3 = CloudStore.onICloudDocumentsGathering(u => {
      console.log(`onICloudDocumentsGathering:`, u);
    });

    const e4 = CloudStore.onICloudDocumentsFinishGathering(u => {
      console.log(`onICloudDocumentsFinishGathering:`, u);
    });

    const e5 = CloudStore.onICloudDocumentsUpdateGathering(u => {
      console.log(`onICloudDocumentsUpdateGathering:`, u);
    });

    return () => {
      e1.remove();
      e2.remove();
      e3.remove();
      e4.remove();
      e5.remove();
    };
  }, []);

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      style={{
        flex: 1,
      }}>
      {/* Dir viewers */}
      <ScrollView
        style={{
          backgroundColor: 'skyblue',
          width: '100%',
          flexBasis: '40%',
        }}>
        <DirReader baseDir={Dirs.DocumentDir} listHeight={80} />
        <DirReader
          baseDir={PathUtils.join(defaultICloudContainerPath, 'Documents')}
          listHeight={200}
        />
      </ScrollView>

      <ScrollView
        style={{flexGrow: 1}}
        contentContainerStyle={{
          paddingBottom: 50,
        }}>
        <Demo1 />
        <Demo2 />
        <Demo3 />
        <Demo4 />
        <Demo5 />
        <Demo6 />
        <View style={{height: 1, borderWidth: 1, borderColor: 'gray'}} />
        <Demo7 />
        <Demo10 />
        <Demo11 />
      </ScrollView>
    </KeyboardAvoidingView>
  );
};

const Demo1 = () => {
  return (
    <Block label={'demo1'}>
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
            'default icloud path from constants:',
            CloudStore.defaultICloudContainerPath,
          );

          CloudStore.getDefaultICloudContainerPath().then(p => {
            console.log('default icloud path from function:', p);
          });
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
  );
};
const Demo2 = () => {
  const [dirForReadOnly, setDirForReadOnly] = useState(
    PathUtils.join(defaultICloudContainerPath, 'Documents'),
  );

  return (
    <Block label={'demo2'}>
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
              console.log(`[dirs of "${dirForReadOnly}"]:\n`, dirs.join('\n'));
            } catch (e) {
              console.error(e);
            }
          }}
        />
      </View>
    </Block>
  );
};
const Demo3 = () => {
  const [dirForCreate, setDirForCreate] = useState(
    PathUtils.join(defaultICloudContainerPath, '/Documents/test-create'),
  );
  return (
    <Block label={'demo3'}>
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
  );
};
const Demo4 = () => {
  const [dirForMoveFrom, setDirForMoveFrom] = useState('');
  const [dirForMoveDest, setDirForMoveDest] = useState('');

  return (
    <Block label={'demo4'}>
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
  );
};
const Demo5 = () => {
  const [filePathForWrite, setFilePathForWrite] = useState(
    PathUtils.join(
      defaultICloudContainerPath,
      'Documents/test-create/demo.txt',
    ),
  );
  const [fileContentForWrite, setFileContentForWrite] = useState('some text');
  return (
    <Block label={'demo5'}>
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
            await CloudStore.writeFile(filePathForWrite, fileContentForWrite, {
              override: true,
            });
            console.log('wrote file');
          } catch (e) {
            console.error(e);
          }
        }}
      />
      <Button
        title={'write file with onProgress'}
        onPress={async () => {
          try {
            await CloudStore.writeFile(
              filePathForWrite,
              new Array(10000).fill('sth').join(','),
              {
                override: true,
                onProgress(data) {
                  console.log('write file progress:', data);
                },
              },
            );
          } catch (e) {
            console.error(e);
          }
        }}
      />
    </Block>
  );
};
const Demo6 = () => {
  const [fileForReadOnly, setFileForReadOnly] = useState(
    PathUtils.join(defaultICloudContainerPath, 'Documents/test-create/demo.tx'),
  );
  return (
    <Block label={'demo6'}>
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
  );
};
const Demo7 = () => {
  const [fileForDownload, setFileForDownload] = useState(
    PathUtils.join(defaultICloudContainerPath, 'Documents/file-on-cloud.txt'),
  );
  const [fileForStore, setFileForStore] = useState(
    RNFS.DocumentDirectoryPath + '/',
  );

  return (
    <Block label={'demo7'}>
      <Input
        value={fileForDownload}
        onChangeText={setFileForDownload}
        placeholder={'file path'}
      />
      <Button
        title={'download'}
        onPress={async () => {
          try {
            await CloudStore.download(fileForDownload, {
              onProgress({progress}) {
                console.log('progress:', progress);
              },
            });
            console.log('download called');
          } catch (e) {
            console.error(e);
          }
        }}
      />

      <Button
        title={'download multiple files'}
        onPress={async () => {
          try {
            await CloudStore.download(
              PathUtils.join(
                defaultICloudContainerPath,
                'Documents/.f1.txt.icloud',
              ),
              {
                onProgress({progress}) {
                  console.log('f1:', progress);
                },
              },
            );
            await CloudStore.download(
              PathUtils.join(
                defaultICloudContainerPath,
                'Documents/.f2.txt.icloud',
              ),
              {
                onProgress({progress}) {
                  console.log('f2:', progress);
                },
              },
            );
            await CloudStore.download(
              PathUtils.join(
                defaultICloudContainerPath,
                'Documents/.f3.txt.icloud',
              ),
              {
                onProgress({progress}) {
                  console.log('f3:', progress);
                },
              },
            );

            console.log('download called');
          } catch (e) {
            console.error('download error:', e);
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
  );
};
const Demo10 = () => {
  const [fileForUpload, setFileForUpload] = useState(
    RNFS.DocumentDirectoryPath + '/local-file.txt',
  );
  const [fileUploadedTo, setFileUploadedTo] = useState(
    CloudStore.defaultICloudContainerPath +
      '/Documents/file-uploaded-from-local.txt',
  );

  return (
    <>
      <Block label={'demo10'}>
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
    </>
  );
};
const Demo11 = () => {
  const [fileForShare, setFileForShare] = useState(
    CloudStore.defaultICloudContainerPath + '/Documents/test-create/demo.txt',
  );
  const [expireSeconds, setExpireSeconds] = useState<number>();

  return (
    <>
      <Block label={'demo11'}>
        <Input
          value={fileForShare}
          onChangeText={setFileForShare}
          placeholder={'icloud file path'}
        />
        <Input
          value={expireSeconds?.toString()}
          onChangeText={txt => {
            setExpireSeconds(Number(txt));
          }}
          keyboardType={'numeric'}
          placeholder={'expire seconds'}
        />
        <Button
          title={'getUrlForPublishingUbiquitousItem'}
          onPress={async () => {
            try {
              const url = await CloudStore.getUrlForPublishingUbiquitousItem(
                fileForShare,
                expireSeconds ? Date.now() + expireSeconds * 1000 : undefined,
              );
              console.log('url for sharing:', url);
            } catch (e) {
              console.error('getUrlForPublishingUbiquitousItem error:', e);
            }
          }}
        />
      </Block>
    </>
  );
};

export default IOSICloudScreen;

import React, {useEffect} from 'react';
import {Button, SafeAreaView, ScrollView, Text, View} from 'react-native';
import * as CloudStore from 'react-native-cloud-store';
import * as RNFS from 'react-native-fs';

const App = () => {
  useEffect(() => {
    const r1 = CloudStore.onICloudKVStoreRemoteChange(u => {
      console.log('onICloudKVStoreRemoteChange:', u);
    });

    const r2 = CloudStore.onICloudDocumentsStartGathering(u => {
      console.log('onICloudDocumentsStartGathering:', u);
    });

    const r3 = CloudStore.onICloudDocumentsGathering(u => {
      console.log('onICloudDocumentsGathering:', u);
    });

    const r4 = CloudStore.onICloudDocumentsFinishGathering(u => {
      console.log('onICloudDocumentsFinishGathering:', u);
    });

    const r5 = CloudStore.onICloudDocumentsUpdateGathering(u => {
      console.log('onICloudDocumentsUpdateGathering:', u);
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
    <SafeAreaView>
      <ScrollView>
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
          title={'getConstants'}
          onPress={() => {
            try {
              const xx = CloudStore.getConstants();
              console.log('getConstants:', xx);
            } catch (e) {
              console.error(e);
            }
          }}
        />

        <View>
          <Text>kv test</Text>
          <Button
            title={'get all'}
            onPress={async () => {
              try {
                const items = await CloudStore.kvGetAllItems();
                console.log('all kv items:', items);
              } catch (e) {
                console.error(e);
              }
            }}
          />
          <Button
            title={'set'}
            onPress={async () => {
              try {
                await CloudStore.kvSetItem('abbb', '2');
                // await CloudStore.kvSync();
                console.log('set done');
              } catch (e) {
                console.error(e);
              }
            }}
          />
          <Button
            title={'get'}
            onPress={async () => {
              try {
                const val = await CloudStore.kvGetItem('abbb');
                console.log('get item:', val);
              } catch (e) {
                console.error(e);
              }
            }}
          />
          <Button
            title={'remove'}
            onPress={async () => {
              try {
                await CloudStore.kvRemoveItem('abbb');
                console.log('removed item');
              } catch (e) {
                console.error(e);
              }
            }}
          />
        </View>

        <View>
          <Text>document test</Text>

          <Text>file test</Text>
          <Button
            title={'write file'}
            onPress={async () => {
              try {
                await CloudStore.writeFile('Documents/test.txt', 'haha');
                console.log('wrote file');
              } catch (e) {
                console.error(e);
              }
            }}
          />
          <Button
            title={'read file'}
            onPress={async () => {
              try {
                const val = await CloudStore.readFile(
                  'Documents/test-from-local.txt',
                );
                console.log('read file:', val);
              } catch (e) {
                console.error(e);
              }
            }}
          />
          <Button
            title={'remove file'}
            onPress={async () => {
              try {
                await CloudStore.unlink('Documents/test-from-local.txt');
                console.log('removed file');
              } catch (e) {
                console.error(e);
              }
            }}
          />
          <Button
            title={'file exists'}
            onPress={async () => {
              try {
                const val = await CloudStore.exist('Documents/test.txt');
                console.log('file exists:', val);
              } catch (e) {
                console.error(e);
              }
            }}
          />
          <Button
            title={'download from icloud to local'}
            onPress={async () => {
              try {
                await CloudStore.downloadToLocal(
                  'Documents/test-from-local.txt',
                  RNFS.DocumentDirectoryPath + '/test-from-icloud.txt',
                );
                console.log('done');
              } catch (e) {
                console.error(e);
              }
            }}
          />

          <Button
            title={'copy local to icloud'}
            onPress={async () => {
              try {
                await CloudStore.copyFromLocal(
                  'file://' + RNFS.DocumentDirectoryPath + '/test.txt',
                  'Documents/test-from-local.txt',
                );
                console.log('done');
              } catch (e) {
                console.error(e);
              }
            }}
          />

          <Button
            title={'move downloaded to local'}
            onPress={async () => {
              try {
                await RNFS.copyFile(
                  CloudStore.getConstants().icloudContainerPath +
                    '/Documents/test-from-local.txt',
                  'file://' +
                    RNFS.DocumentDirectoryPath +
                    '/copied-from-icloud.txt',
                );
                console.log('done');
              } catch (e) {
                console.error(e);
              }
            }}
          />

          <Text>dir test</Text>
          <Button
            title={'create dir'}
            onPress={async () => {
              try {
                await CloudStore.createDir('myfoler');
                console.log('created dir');
              } catch (e) {
                console.error(e);
              }
            }}
          />
          <Button
            title={'read dir'}
            onPress={async () => {
              try {
                const dirs = await CloudStore.readDir('Documents');
                console.log('dirs:', dirs.join(','));
              } catch (e) {
                console.error(e);
              }
            }}
          />
          <Button
            title={'move dir'}
            onPress={async () => {
              try {
                await CloudStore.moveDir('/myfoler', '/destFolder');
                console.log('moved');
              } catch (e) {
                console.error(e);
              }
            }}
          />
        </View>

        <View>
          <Text>local documents test</Text>
          <Button
            title={'write file'}
            onPress={() => {
              var path = RNFS.DocumentDirectoryPath + '/test.txt';

              // write the file
              RNFS.writeFile(
                path,
                'Lorem ipsum dolor sit amet  newwwwwwwwww222',
                'utf8',
              )
                .then(_success => {
                  console.log('FILE WRITTEN!');
                })
                .catch(err => {
                  console.log(err.message);
                });
            }}
          />
          <Button
            title={'list'}
            onPress={() => {
              RNFS.readDir(RNFS.DocumentDirectoryPath)
                .then(success => {
                  console.log(success);
                })
                .catch(err => {
                  console.log(err.message);
                });
            }}
          />
          <Button
            title={'delete'}
            onPress={() => {
              RNFS.unlink(
                RNFS.DocumentDirectoryPath + '/copied-from-icloud.txt',
              )
                .then(() => {
                  console.log('done');
                })
                .catch(err => {
                  console.log(err.message);
                });
            }}
          />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

export default App;

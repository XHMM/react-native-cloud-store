import React, {useEffect, useState} from 'react';
import {
  Button,
  Platform,
  PlatformIOSStatic,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import * as CloudStore from 'react-native-cloud-store';
import * as RNFS from 'react-native-fs';

const platform = Platform as PlatformIOSStatic;
const label = `[${platform.constants.systemName} ${platform.constants.osVersion}]`;

const App = () => {
  const [kvKey, setKVKey] = useState('');
  const [kvValue, setKVValue] = useState('');

  const [dir, setDir] = useState('Documents');
  const [destDir, setDestDir] = useState('');

  const [file, setFile] = useState('');
  const [fileContent, setFileContent] = useState('');

  const [localFilePath, setLocalFilePath] = useState('');
  const [icloudFilePath, setICloudFilePath] = useState('');

  useEffect(() => {
    const r1 = CloudStore.onICloudKVStoreRemoteChange(u => {
      console.log(`${label} onICloudKVStoreRemoteChange:`, u);
    });

    const r2 = CloudStore.onICloudDocumentsStartGathering(u => {
      console.log(`${label} onICloudDocumentsStartGathering:`, u);
    });

    const r3 = CloudStore.onICloudDocumentsGathering(u => {
      console.log(`${label} onICloudDocumentsGathering:`, u);
    });

    const r4 = CloudStore.onICloudDocumentsFinishGathering(u => {
      console.log(`${label} onICloudDocumentsFinishGathering:`, u);
    });

    const r5 = CloudStore.onICloudDocumentsUpdateGathering(u => {
      console.log(`${label} onICloudDocumentsUpdateGathering:`, u);
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
        <Text style={styles.title}>chores api</Text>
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
          <Text style={styles.title}>kv test</Text>
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
          <View>
            <TextInput
              style={styles.input}
              value={kvKey}
              onChangeText={setKVKey}
              placeholder={'key'}
            />
            <TextInput
              style={styles.input}
              value={kvValue}
              onChangeText={setKVValue}
              placeholder={'value'}
            />
          </View>

          <Button
            title={'set'}
            onPress={async () => {
              try {
                await CloudStore.kvSetItem(kvKey, kvValue);
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
                const val = await CloudStore.kvGetItem(kvKey);
                console.log(`get ${kvKey}:`, val);
              } catch (e) {
                console.error(e);
              }
            }}
          />
          <Button
            title={'remove'}
            onPress={async () => {
              try {
                await CloudStore.kvRemoveItem(kvKey);
                console.log(`removed ${kvKey}`);
              } catch (e) {
                console.error(e);
              }
            }}
          />
        </View>

        <View>
          <Text style={styles.title}>document test</Text>

          <Text style={styles.subtitle}>dir test</Text>
          <TextInput
            style={styles.input}
            value={dir}
            onChangeText={setDir}
            placeholder={'dir relative path'}
          />
          <Button
            title={'stat dir'}
            onPress={async () => {
              try {
                const val = await CloudStore.stat(dir);
                console.log(`stat of ${dir}:`, JSON.stringify(val, null, 2));
              } catch (e) {
                console.error(e);
              }
            }}
          />
          <Button
            title={'create dir'}
            onPress={async () => {
              try {
                await CloudStore.createDir(dir);
                console.log(`created dir of ${dir}`);
              } catch (e) {
                console.error(e);
              }
            }}
          />
          <Button
            title={'read dir'}
            onPress={async () => {
              try {
                const dirs = await CloudStore.readDir(dir);
                console.log(`dirs of ${dir}:`, dirs.join(',\n'));
              } catch (e) {
                console.error(e);
              }
            }}
          />

          <TextInput
            style={styles.input}
            value={destDir}
            onChangeText={setDestDir}
            placeholder={'dest dir path'}
          />
          <Button
            title={'move dir'}
            onPress={async () => {
              try {
                await CloudStore.moveDir(dir, destDir);
                console.log(`moved from ${dir} to ${destDir}`);
              } catch (e) {
                console.error(e);
              }
            }}
          />

          <Text style={styles.subtitle}>file test</Text>
          <TextInput
            style={styles.input}
            value={file}
            onChangeText={setFile}
            placeholder={'file relative path'}
          />
          <Button
            title={'stat file'}
            onPress={async () => {
              try {
                const val = await CloudStore.stat(file);
                console.log(`stat of ${file}:`, val);
              } catch (e) {
                console.error(e);
              }
            }}
          />

          <TextInput
            style={styles.input}
            value={fileContent}
            onChangeText={setFileContent}
            placeholder={'file content'}
          />
          <Button
            title={'write file'}
            onPress={async () => {
              try {
                await CloudStore.writeFile(file, fileContent);
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
                const val = await CloudStore.readFile(file);
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
                await CloudStore.unlink(file);
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
                const val = await CloudStore.exist(
                  'Documents/copied-from-icloud.txt',
                );
                console.log('file exists:', val);
              } catch (e) {
                console.error(e);
              }
            }}
          />
          <Button
            title={'persist/download'}
            onPress={async () => {
              try {
                await CloudStore.persist(file);
                console.log('done');
              } catch (e) {
                console.error(e);
              }
            }}
          />

          <Button
            title={'copy persisted(downloaded) file to local'}
            onPress={async () => {
              try {
                await RNFS.copyFile(
                  CloudStore.getConstants().iCloudContainerPath +
                    '/Documents/test.txt',
                  'file://' + RNFS.DocumentDirectoryPath + '/test.txt',
                );
                console.log('done');
              } catch (e) {
                console.error(e);
              }
            }}
          />
        </View>

        <View>
          <Text style={styles.subtitle}>local documents test</Text>
          <Button
            title={'write to local file'}
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
            title={'list local files'}
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

          <TextInput
            style={styles.input}
            value={localFilePath}
            onChangeText={setLocalFilePath}
            placeholder={'local file path relative to app documents(no prefix)'}
          />
          <TextInput
            style={styles.input}
            value={icloudFilePath}
            onChangeText={setICloudFilePath}
            placeholder={'icloud file path'}
          />
          <Button
            title={'upload local file to icloud'}
            onPress={async () => {
              try {
                await CloudStore.upload(
                  'file://' + RNFS.DocumentDirectoryPath + '/' + localFilePath,
                  icloudFilePath,
                );
              } catch (e) {
                console.error(e);
              }
            }}
          />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  title: {
    fontWeight: 'bold',
    fontSize: 30,
  },
  subtitle: {
    fontWeight: 'bold',
    fontSize: 23,
    color: 'gray',
  },
  input: {
    height: 40,
    margin: 12,
    borderWidth: 1,
    padding: 10,
  },
});

export default App;

import React from 'react';
import {Button, SafeAreaView, Text, View} from 'react-native';
import * as CloudStore from 'react-native-cloud-store';

const App = () => {
  return (
    <SafeAreaView>
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
              await CloudStore.writeFile('abbb', 'haha');
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
              const val = await CloudStore.readFile('abbb');
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
              await CloudStore.unlink('abbb');
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
              const val = await CloudStore.fileOrDirExists('myfile');
              console.log('file exists:', val);
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
              const dirs = await CloudStore.readDir('/');
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
    </SafeAreaView>
  );
};

export default App;

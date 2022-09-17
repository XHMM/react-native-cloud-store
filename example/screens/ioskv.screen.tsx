import React, {FC, useEffect, useState} from 'react';
import {ScrollView, View} from 'react-native';
import * as CloudStore from 'react-native-cloud-store';
import Input from '../components/input';
import Block from '../components/Block';
import Button from '../components/Button';

interface Props {}

const IOSKVScreen: FC<Props> = ({}) => {
  const [keyForSet, setKeyForSet] = useState('');
  const [valueForSet, setValueForSet] = useState('');

  const [keyForGet, setKeyForGet] = useState('');
  const [keyForDelete, setKeyForDelete] = useState('');

  useEffect(() => {
    const r1 = CloudStore.onICloudKVStoreRemoteChange(u => {
      console.log(`onICloudKVStoreRemoteChange:`, u);
    });
    return () => {
      r1.remove();
    };
  }, []);

  return (
    <ScrollView
      style={{flex: 1}}
      contentContainerStyle={{
        paddingBottom: 10,
      }}>
      <Block>
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
      </Block>

      <Block>
        <Input value={keyForSet} onChangeText={setKeyForSet} placeholder={'key'} />
        <Input
          value={valueForSet}
          onChangeText={setValueForSet}
          placeholder={'value'}
        />
        <Button
          title={'set'}
          onPress={async () => {
            try {
              await CloudStore.kvSetItem(keyForSet, valueForSet);
              // await CloudStore.kvSync();
              console.log('set done');
            } catch (e) {
              console.error(e);
            }
          }}
        />
      </Block>

      <Block>
        <Input value={keyForGet} onChangeText={setKeyForGet} placeholder={'key'} />
        <Button
          title={'get'}
          onPress={async () => {
            try {
              const val = await CloudStore.kvGetItem(keyForGet);
              console.log(`get value of "${keyForGet}":`, val);
            } catch (e) {
              console.error(e);
            }
          }}
        />
      </Block>

      <Block>
        <Input value={keyForDelete} onChangeText={setKeyForDelete} placeholder={'key for delete'} />
        <Button
          title={'remove'}
          onPress={async () => {
            try {
              await CloudStore.kvRemoveItem(keyForDelete);
              console.log(`removed "${keyForDelete}"`);
            } catch (e) {
              console.error(e);
            }
          }}
        />
      </Block>
    </ScrollView>
  );
};

export default IOSKVScreen;

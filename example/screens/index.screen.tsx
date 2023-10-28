import React, {FC} from 'react';
import {View} from 'react-native';
import {useNavigation} from '@react-navigation/native';
import Button from '../components/Button';

interface Props {}

const IndexScreen: FC<Props> = () => {
  const navigation = useNavigation<any>();

  return (
    <View
      style={{
        flex: 1,
        justifyContent: 'center',
      }}>
      {[
        {title: 'ios icloud', target: 'ios-icloud'},
        {title: 'ios key-value storage', target: 'ios-kv'},
      ].map(i => {
        return (
          <Button
            title={i.title}
            style={{flexGrow: 0}}
            key={i.target}
            onPress={() => {
              navigation.navigate(i.target);
            }}
          />
        );
      })}
    </View>
  );
};

export default IndexScreen;

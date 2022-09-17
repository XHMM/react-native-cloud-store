import React, { FC } from 'react';
import { View, Text } from 'react-native';

interface Props {
  title: string
}
const Title: FC<Props> = ({title}) => {
  return <>
  <View>
    <Text style={{
      fontSize: 18,
      fontWeight:'bold',
      marginVertical: 10
    }}>{title}</Text>
  </View>
  </>;
};

export default Title;

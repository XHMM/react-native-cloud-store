import React, {FC} from 'react';
import {View, Text} from 'react-native';

interface Props {
  label?: string
}

const Block: FC<Props> = ({children, label}) => {
  return (
    <View
      style={{
        padding: 5,
        margin: 10,
        borderRadius: 10,
        backgroundColor: 'white',
        elevation: 2,
        shadowColor: 'gray',
        shadowRadius:4,
        shadowOffset: {
          width: 1,
          height: 10,
        },
        shadowOpacity: 0.05,
      }}>
      <Text style={{
        fontSize: 10
      }}>{label}</Text>
      {children}
    </View>
  );
};

export default Block;

import React, {FC} from 'react';
import {View} from 'react-native';

interface Props {}

const Block: FC<Props> = ({children}) => {
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
      {children}
    </View>
  );
};

export default Block;

import React, { FC } from 'react';
import { StyleSheet, TextInput, TextInputProps } from 'react-native';

interface Props {}
const Input: FC<Props & TextInputProps> = (props) => {
  return <>
    <TextInput
      style={styles.input}
      {...props}
      multiline
    />
  </>;
};

export default Input;

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
    margin: 12,
    borderWidth: 1,
    padding: 10,
    borderRadius:5
  },
});

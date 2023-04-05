import React, { FC } from 'react';
import { StyleSheet, Text, TouchableOpacity, TouchableWithoutFeedbackProps } from 'react-native';

interface Props {
  title:string
}
const Button: FC<Props & TouchableWithoutFeedbackProps> = ({title, ...rest}) => {
  return <><TouchableOpacity  {...rest} style={[styles.button, rest.style]}><Text style={styles.text}>{title}</Text></TouchableOpacity></>;
};


const styles = StyleSheet.create({
  button: {
    marginVertical: 5,
    flexShrink:0,
    flexGrow:1,
    marginHorizontal: 5,
    paddingVertical: 5,
    alignItems:'center',
    borderRadius:5,
    borderColor:'black',
    backgroundColor:'orange'
  },
  text: {
    color: 'white',
    fontSize: 17
  }
})

export default Button;

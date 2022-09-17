import React from 'react';
import {NavigationContainer} from '@react-navigation/native';
import {createNativeStackNavigator} from '@react-navigation/native-stack';
import IOSKVScreen from './screens/ioskv.screen';
import IOSICloudScreen from './screens/iosicloud.screen';
import IndexScreen from './screens/index.screen';

const Stack = createNativeStackNavigator();
const App = () => {
  return (
    <NavigationContainer>
      <Stack.Navigator>
        <Stack.Screen
          name={'index'}
          component={IndexScreen}
          options={{
            title:"cloud-store demo",
          }}
        />
        <Stack.Screen
          name={'ios-kv'}
          component={IOSKVScreen}
          options={{
            title: 'Key-value Storage Demo',
          }}
        />
        <Stack.Screen
          name={'ios-icloud'}
          component={IOSICloudScreen}
          options={{
            title: 'iCloud Demo',
          }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
};

export default App;

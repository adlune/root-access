import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { StyleSheet, View } from 'react-native';

import { NoticeToast } from '@/components/notice-toast';
import { Colors } from '@/constants/theme';
import { GameProvider } from '@/game/game-provider';

export default function RootLayout() {
  return (
    <GameProvider>
      <View style={styles.root}>
        <StatusBar style="light" />
        <Stack
          screenOptions={{
            headerShown: false,
            contentStyle: { backgroundColor: Colors.background },
          }}
        />
        <NoticeToast />
      </View>
    </GameProvider>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: Colors.background,
  },
});

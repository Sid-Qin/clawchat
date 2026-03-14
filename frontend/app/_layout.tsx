import { Slot } from "expo-router";
import { StyleSheet } from "react-native";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { ThemeProvider } from "../src/theme/ThemeContext";

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={styles.container}>
      <ThemeProvider>
        <Slot />
      </ThemeProvider>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});

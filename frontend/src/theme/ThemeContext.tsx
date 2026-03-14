import React, { createContext, useState, useEffect } from 'react';
import { useColorScheme } from 'react-native';
import { lightColors, darkColors, Colors } from './colors';
import { spacing, radius } from './spacing';
import { typography } from './typography';

interface ThemeContextType {
  isDark: boolean;
  colors: Colors;
  spacing: typeof spacing;
  radius: typeof radius;
  typography: typeof typography;
  toggleTheme: () => void;
}

export const ThemeContext = createContext<ThemeContextType>({
  isDark: false,
  colors: lightColors,
  spacing,
  radius,
  typography,
  toggleTheme: () => {},
});

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const systemColorScheme = useColorScheme();
  const [isDark, setIsDark] = useState(systemColorScheme === 'dark');

  useEffect(() => {
    setIsDark(systemColorScheme === 'dark');
  }, [systemColorScheme]);

  const toggleTheme = () => setIsDark(!isDark);

  const theme = {
    isDark,
    colors: isDark ? darkColors : lightColors,
    spacing,
    radius,
    typography,
    toggleTheme,
  };

  return <ThemeContext.Provider value={theme}>{children}</ThemeContext.Provider>;
};

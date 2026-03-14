export const lightColors = {
  background: '#F2F3F5',
  card: 'rgba(255, 255, 255, 0.72)',
  primary: '#5865F2',
  textMain: '#1E1F22',
  textMuted: '#6D6F78',
  border: 'rgba(0, 0, 0, 0.06)',
  glassTint: 'light' as const,
  sidebar: '#E3E5E8',
  panel: '#EBEDEF',
  success: '#23A559',
  danger: '#DA373C',
};

export const darkColors = {
  background: '#1E1F22',
  card: 'rgba(30, 31, 34, 0.8)',
  primary: '#5865F2',
  textMain: '#F2F3F5',
  textMuted: '#949BA4',
  border: 'rgba(255, 255, 255, 0.06)',
  glassTint: 'dark' as const,
  sidebar: '#111214',
  panel: '#2B2D31',
  success: '#23A559',
  danger: '#DA373C',
};

export type Colors = typeof lightColors | typeof darkColors;

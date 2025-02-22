import Notifications from './features/notifications/NotificationWrapper';
import CircleProgressbar from './features/progress/CircleProgressbar';
import Progressbar from './features/progress/Progressbar';
import { useNuiEvent } from './hooks/useNuiEvent';
import { setClipboard } from './utils/setClipboard';
import { fetchNui } from './utils/fetchNui';
import HintUI from './features/hints/HintUI';
import TextUI from './features/textui/TextUI';
import Dev from './features/dev';
import { isEnvBrowser } from './utils/misc';
import { theme } from './theme';
import { MantineProvider } from '@mantine/core';
import { useConfig } from './providers/ConfigProvider';

const App: React.FC = () => {
  const { config } = useConfig();

  useNuiEvent('setClipboard', (data: string) => {
    setClipboard(data);
  });

  fetchNui('init');

  return (
    <MantineProvider withNormalizeCSS withGlobalStyles theme={{ ...theme, ...config }}>
      <Progressbar />
      <CircleProgressbar />
      <Notifications />
      <HintUI />
      <TextUI />
      {isEnvBrowser() && <Dev />}
    </MantineProvider>
  );
};

export default App;
import { ActionIcon, Button, Divider, Drawer, Stack, Tooltip } from '@mantine/core';
import { debugCustomNotification } from './debug/notification';
import { debugCircleProgressbar, debugProgressbar } from './debug/progress';
import { debugHintUI } from './debug/hintui';
import { useState } from 'react';
import LibIcon from '../../components/LibIcon';

const Dev: React.FC = () => {
  const [opened, setOpened] = useState(false);

  return (
    <>
      <Tooltip label="Developer drawer" position="bottom">
        <ActionIcon
          onClick={() => setOpened(true)}
          radius="xl"
          variant="filled"
          color="orange"
          sx={{ position: 'absolute', bottom: 0, right: 0, width: 50, height: 50 }}
          size="xl"
          mr={50}
          mb={50}
        >
          <LibIcon icon="wrench" fontSize={24} />
        </ActionIcon>
      </Tooltip>

      <Drawer position="left" onClose={() => setOpened(false)} opened={opened} title="Developer drawer" padding="xl">
        <Stack>
          <Divider />
          <Button fullWidth onClick={() => { debugCustomNotification(); setOpened(false); }}>
            Send notification
          </Button>
          <Divider />
          <Button fullWidth onClick={() => { debugProgressbar(); setOpened(false); }}>
            Activate progress bar
          </Button>
          <Button fullWidth onClick={() => { debugCircleProgressbar(); setOpened(false); }}>
            Activate progress circle
          </Button>
          <Divider />
          <Button fullWidth onClick={() => { debugHintUI(); setOpened(false); }}>
            Show HintUI
          </Button>
        </Stack>
      </Drawer>
    </>
  );
};

export default Dev;

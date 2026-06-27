import { useNuiEvent } from '../../hooks/useNuiEvent';
import { toast, Toaster } from 'react-hot-toast';
import ReactMarkdown from 'react-markdown';
import { Center, Box, createStyles, Group, keyframes, RingProgress, Stack, Text } from '@mantine/core';
import React, { useState } from 'react';
import tinycolor from 'tinycolor2';
import type { NotificationProps } from '../../typings';
import MarkdownComponents from '../../config/MarkdownComponents';

import InfoSvg from "./InfoSvg";
import ErrorSvg from "./ErrorSvg";
import WarningSvg from "./WarningSvg";
import CheckSvg from "./CheckSvg";

const useStyles = createStyles((theme) => ({
  container: {
    width: 300,
    height: 'fit-content',
    backgroundColor: theme.colors.dark[6],
    color: theme.colors.dark[0],
    padding: 12,
    borderRadius: theme.radius.sm,
    fontFamily: 'Gilroy',
    boxShadow: theme.shadows.sm,
  },
  title: {
    fontWeight: 500,
    lineHeight: 'normal',
  },
  description: {
    fontSize: 12,
    color: theme.colors.dark[2],
    fontFamily: 'Gilroy',
    lineHeight: 'normal',
  },
  descriptionOnly: {
    fontSize: 14,
    color: theme.colors.dark[2],
    fontFamily: 'Gilroy',
    lineHeight: 'normal',
  },
}));

const createAnimation = (from: string, to: string, visible: boolean) => keyframes({
  from: {
    opacity: visible ? 0 : 1,
    transform: `translate${from}`,
  },
  to: {
    opacity: visible ? 1 : 0,
    transform: `translate${to}`,
  },
});

const getAnimation = (visible: boolean, position: string) => {
  const animationOptions = visible ? '0.2s ease-out forwards' : '0.4s ease-in forwards';
  let animation: { from: string; to: string };

  if (visible) {
    animation = position.includes('bottom')
      ? { from: 'Y(30px)', to: 'Y(0px)' }
      : { from: 'Y(-30px)', to: 'Y(0px)' };
  } else {
    if (position.includes('right')) {
      animation = { from: 'X(0px)', to: 'X(100%)' };
    } else if (position.includes('left')) {
      animation = { from: 'X(0px)', to: 'X(-100%)' };
    } else if (position === 'top-center') {
      animation = { from: 'Y(0px)', to: 'Y(-100%)' };
    } else if (position === 'bottom') {
      animation = { from: 'Y(0px)', to: 'Y(100%)' };
    } else {
      animation = { from: 'X(0px)', to: 'X(100%)' };
    }
  }

  return `${createAnimation(animation.from, animation.to, visible)} ${animationOptions}`;
};

const durationCircle = keyframes({
  '0%': { strokeDasharray: `0, ${15.1 * 2 * Math.PI}` },
  '100%': { strokeDasharray: `${15.1 * 2 * Math.PI}, 0` },
});

const Notifications: React.FC = () => {
  const { classes } = useStyles();
  const [toastKey, setToastKey] = useState(0);

  useNuiEvent<NotificationProps>('notify', (data) => {
    if (!data.title && !data.description) return;

    const toastId = data.id?.toString();
    let position = data.position || 'top-right';

    data.showDuration = data.showDuration !== undefined ? data.showDuration : true;

    switch (position) {
      case 'top':
        position = 'top-center';
        break;
      case 'bottom':
        position = 'bottom-center';
        break;
    }

    if (!data.icon) {
      switch (data.type) {
        case 'error':
          data.icon = 'circle-xmark';
          break;
        case 'success':
          data.icon = 'circle-check';
          break;
        case 'warning':
          data.icon = 'circle-exclamation';
          break;
        default:
          data.icon = 'circle-info';
          break;
      }
    }

    let iconColor: string;
    if (!data.iconColor) {
      switch (data.type) {
        case 'error':
          iconColor = 'red.6';
          break;
        case 'success':
          iconColor = 'teal.6';
          break;
        case 'warning':
          iconColor = 'yellow.6';
          break;
        default:
          iconColor = 'blue.6';
          break;
      }
    } else {
      iconColor = tinycolor(data.iconColor).toRgbString();
    }

    const IconComponent =
      data.type === "success" ? CheckSvg :
      data.type === "error" ? ErrorSvg :
      data.type === "warning" ? WarningSvg :
      InfoSvg;

    const isPersistent = (data as any).persistent === true || data.duration === 0;
    const duration = isPersistent ? Infinity : (data.duration || 3000);

    if (isPersistent) {
      data.showDuration = false;
    }

    if (toastId) setToastKey(prevKey => prevKey + 1);

    toast.custom(
      (t) => (
        <Box
          sx={{
            animation: getAnimation(t.visible, position),
            ...data.style,
          }}
          className={`${classes.container} notification-container ${data.type}`}
        >
          <Group noWrap spacing={12}>
            <Center style={{ width: 32, height: 32 }}>
              <IconComponent />
            </Center>

            <Stack spacing={0}>
              {data.title && <Text className={classes.title}>{data.title}</Text>}
              {data.description && (
                <ReactMarkdown
                  components={MarkdownComponents}
                  className={`${!data.title ? classes.descriptionOnly : classes.description} description`}
                >
                  {data.description}
                </ReactMarkdown>
              )}
            </Stack>

            {data.showDuration && Number.isFinite(duration) && (
              <RingProgress
                key={toastKey}
                size={18}
                thickness={2}
                sections={[{ value: 100, color: iconColor }]}
                style={{ alignSelf: !data.alignIcon || data.alignIcon === 'center' ? 'center' : 'start' }}
                className='notification-icon'
                styles={{
                  root: {
                    '> svg > circle:nth-of-type(2)': {
                      animation: `${durationCircle} linear forwards reverse`,
                      animationDuration: `${duration}ms`,
                    },
                    margin: -3,
                  },
                }}
              />
            )}
          </Group>
        </Box>
      ),
      {
        id: toastId,
        duration: duration,
        position: position as any,
      }
    );
  });

  useNuiEvent<{ id: string | number }>('clearNotification', ({ id }) => {
    if (id === undefined || id === null) return;
    toast.dismiss(id.toString());
  });

  return <Toaster />;
};

export default Notifications;
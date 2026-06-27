import { NotificationProps } from '../../../typings';
import { debugData } from '../../../utils/debugData';

export const debugCustomNotification = () => {
  debugData<NotificationProps>([
    {
      action: 'notify',
      data: {
        title: 'Error',
        description: 'Notification description',
        type: 'error',
        duration: 50000,
      },
    },
  ]);

  debugData<NotificationProps>([
    {
      action: 'notify',
      data: {
        title: 'Inform',
        description: 'Notification description',
        type: 'inform',
        duration: 50000,
      },
    },
  ]);

  debugData<NotificationProps>([
    {
      action: 'notify',
      data: {
        title: 'Success',
        description: 'Notification description',
        type: 'success',
        duration: 50000,
      },
    },
  ]);

  debugData<NotificationProps>([
    {
      action: 'notify',
      data: {
        title: 'Warning',
        description: 'Notification description',
        type: 'warning',
        duration: 50000,
      },
    },
  ]);
};

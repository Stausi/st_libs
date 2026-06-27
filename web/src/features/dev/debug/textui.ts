import { debugData } from '../../../utils/debugData';
import { TextUiProps } from '../../../typings';

export const debugTextUI = () => {
  debugData<TextUiProps>([
    {
      action: 'textUI',
      data: {
        show: true,
        keyText: 'E',
        displayText: 'Garage',
      },
    },
  ]);
};
import { HintUiProps } from '../../../typings';
import { debugData } from '../../../utils/debugData';

export const debugHintUI = () => {
  debugData<HintUiProps>([
    {
      action: 'hintUI',
      data: {
        title: 'Current Task',
        text: 'Do something',
        position: 'left-center',
        button: 'E',
      },
    },
  ]);
};
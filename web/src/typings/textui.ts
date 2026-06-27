export type TextUiPosition = 'right-center' | 'left-center' | 'top-center' | 'bottom-center';

export interface TextUiProps {
  show: boolean;
  keyText: string;
  displayText: string;
  hideKey?: boolean;
  position?: TextUiPosition;
}
import { IconProp } from '@fortawesome/fontawesome-svg-core';
import React from 'react';
import { IconAnimation } from '../components/LibIcon';

export type HintUiPosition = 'right-center' | 'left-center' | 'top-center' | 'bottom-center';

export interface HintUiProps {
  title: string;
  text: string;
  position?: HintUiPosition;
  icon?: IconProp;
  iconColor?: string;
  iconAnimation?: IconAnimation;
  style?: React.CSSProperties;
  alignIcon?: 'top' | 'center';
  button?: string;
}
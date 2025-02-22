import { FontAwesomeIcon, FontAwesomeIconProps } from '@fortawesome/react-fontawesome';

export type IconAnimation =
  | 'spin'
  | 'spinPulse'
  | 'spinReverse'
  | 'pulse'
  | 'beat'
  | 'fade'
  | 'beatFade'
  | 'bounce'
  | 'shake'
  | 'slowSpin';

const LibIcon: React.FC<FontAwesomeIconProps & { animation?: IconAnimation }> = (props) => {
  const { animation, className, ...rest } = props;

  const animationProps = {
    spin: animation === 'spin',
    spinPulse: animation === 'spinPulse',
    spinReverse: animation === 'spinReverse',
    pulse: animation === 'pulse',
    beat: animation === 'beat',
    fade: animation === 'fade',
    beatFade: animation === 'beatFade',
    bounce: animation === 'bounce',
    shake: animation === 'shake',
  };

  const customClass = animation === 'slowSpin' ? 'slow-spin' : '';
  return <FontAwesomeIcon {...rest} {...animationProps} className={`${className || ''} ${customClass}`} />;
};

export default LibIcon;
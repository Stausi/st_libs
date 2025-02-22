import React from 'react';
import { useNuiEvent } from '../../hooks/useNuiEvent';
import { Box, createStyles, Group } from '@mantine/core';
import ReactMarkdown from 'react-markdown';
import ScaleFade from '../../transitions/ScaleFade';
import remarkGfm from 'remark-gfm';
import type { HintUiPosition, HintUiProps } from '../../typings';
import MarkdownComponents from '../../config/MarkdownComponents';
import LibIcon from '../../components/LibIcon';

const useStyles = createStyles((theme, params: { position?: HintUiPosition }) => {
  const position = params.position || 'left-center';
  const isLeft = position.includes('left');
  const isRight = position.includes('right');

  const hexToRgba = (hex: string, alpha: number) => {
    const bigint = parseInt(hex.slice(1), 16);
    const r = (bigint >> 16) & 255;
    const g = (bigint >> 8) & 255;
    const b = bigint & 255;
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  };

  const primaryColor = theme.fn.primaryColor();
  const primaryRgba = hexToRgba(primaryColor, 1);
  const primaryTransparent = hexToRgba(primaryColor, 0);

  return {
    wrapper: {
      height: '100%',
      width: '100%',
      position: 'absolute',
      display: 'flex',
      alignItems: 
        position === 'top-center' ? 'baseline' :
        position === 'bottom-center' ? 'flex-end' : 'center',
      justifyContent: 
        isRight ? 'flex-end' :
        isLeft ? 'flex-start' : 'center',
    },
    container: {
      fontSize: 16,
      padding: 16,
      margin: 8,
      backgroundColor: 'rgba(70, 70, 70, 0.5)',
      borderRadius: '0.3vw',
      justifyContent: 'center',
      marginLeft: isLeft ? '1.0vw' : isRight ? '1.0vw' : 0,
      marginRight: isLeft ? '1.0vw' : isRight ? '1.0vw' : 0,
      minWidth: '12vw',
    },
    title: {
      fontSize: '.8vw',
      fontWeight: 600,
      color: '#ffff',
      textShadow: '0 0 0.1vw #000c1e',
      display: 'flex',
      alignItems: 'center',
      gap: '10px',
    },
    description: {
      width: '100%',
      fontSize: '0.7vw',
      fontWeight: 'normal',
      marginBottom: '0.2vw',
      color: '#fff',
      textShadow: '0 0 0.2vw #000c1e',
    },
    button: {
      width: '1.0vw',
      height: '1.8vh',
      background: 'rgba(0, 0, 0, 0.25)',
      borderRadius: '0.08vw',
      textAlign: 'center',
      lineHeight: '1.8vh',
      fontWeight: 600,
      color: 'rgba(255, 255, 255, 0.8)',
      fontSize: '0.6vw',
    },
    buttonText: {
      color: '#fff',
      fontSize: '0.5vw',
      fontWeight: 600,
    },
    dividerLine: {
      width: '100%',
      height: '0.07vh',
      background: `linear-gradient(${isLeft ? '90deg' : isRight ? '270deg' : '0deg'}, 
        ${primaryRgba} 0%, 
        ${primaryRgba} 50%, 
        ${primaryTransparent} 100%)`,
      border: 'none',
      margin: '0.5vw 0',
    },
    close: {
      display: 'flex',
      flexDirection: 'row',
      marginTop: '0.69vh',
      alignItems: 'left',
      justifyContent: 'left',
      color: 'rgba(255,255,255,0.5)',
      fontSize: '0.5vw',
    },
  };
});

const HintUI: React.FC = () => {
  const [data, setData] = React.useState<HintUiProps>({
    title: '',
    text: '',
    button: '',
  });
  const [visible, setVisible] = React.useState(false);
  const { classes } = useStyles({ position: data.position });

  useNuiEvent<HintUiProps>('hintUI', (data) => {
    setData(data);
    setVisible(true);
  });

  useNuiEvent('hintUiHide', () => setVisible(false));

  return (
    <Box className={classes.wrapper}>
      <ScaleFade visible={visible}>
        <Box className={classes.container}>
          <Group spacing={12} className={classes.title}>
            <LibIcon icon="spinner" fixedWidth size="lg" animation="slowSpin" style={{ color: '#ffff', textShadow: '0 0 0.2vw #000c1e' }} />
            <span>{data.title}</span>
          </Group>
          <hr className={classes.dividerLine} />
          <ReactMarkdown components={MarkdownComponents} remarkPlugins={[remarkGfm]} className={classes.description}>
            {data.text}
          </ReactMarkdown>
          <Group spacing={12} mt={12} align="center" className={classes.close}>
            <Box className={classes.button}>{data.button}</Box>
            <span className={classes.buttonText}>Tryk for at skjule.</span>
          </Group>
        </Box>
      </ScaleFade>
    </Box>
  );
};

export default HintUI;
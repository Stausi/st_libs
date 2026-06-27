import React from 'react';
import { useNuiEvent } from '../../hooks/useNuiEvent';
import { Box, createStyles, Group } from '@mantine/core';
import ReactMarkdown from 'react-markdown';
import ScaleFade from '../../transitions/ScaleFade';
import remarkGfm from 'remark-gfm';
import type { HintUiProps } from '../../typings';
import MarkdownComponents from '../../config/MarkdownComponents';

const useStyles = createStyles(() => {
  return {
    wrapper: {
      position: 'absolute',
      top: '50%',
      left: '1%',
      transform: 'translateY(-50%)',
      color: '#fff',
      padding: '0.78vw',
      borderRadius: '0.39vw',
      width: 'max-content',
      height: 'max-content',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'left',
      alignItems: 'left',
      border: 'none',
    },
    container: {
      width: '250px',
      padding: '0.5vw',
      boxSizing: 'border-box',
      backgroundColor: 'rgba(70, 70, 70, 0.5)',
      borderRadius: '0.3vw',
    },
    title: {
      fontSize: '18px',
      fontWeight: 600,
      color: 'rgb(255, 255, 255)',
      borderRadius: '2px',
      display: 'flex',
      alignItems: 'center',
      gap: '10px',
      marginLeft: '10px',
    },
    description: {
      width: '100%',
      fontSize: '13px',
      fontWeight: 'normal',
      marginBottom: '0.2vw',
      color: '#fff',
      textShadow: '0 0 0.2vw #000c1e',
    },
    button: {
      width: '25px',
      height: '25px',
      background: 'rgba(0, 0, 0, 0.25)',
      borderRadius: '0.08vw',
      textAlign: 'center',
      lineHeight: '25px',
      fontWeight: 600,
      color: 'rgba(255, 255, 255, 0.8)',
      fontSize: '16px',
    },
    buttonText: {
      color: '#fff',
      fontSize: '12px',
      fontWeight: 600,
    },
    dividerLine: {
      width: '100%',
      height: '0.2vh',
      background: `linear-gradient(87deg, rgba(3,243,214,1) 0%, rgba(3,243,214,1) 50%, rgba(3,243,214,0) 100%)`,
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
  const { classes } = useStyles();

  useNuiEvent<HintUiProps>('hintUI', (data) => {
    setData(data);
    setVisible(true);
  });

  useNuiEvent('hintUpdate', (data) => {
    setData((prev) => ({
      ...prev,
      title: data.title || prev.title,
      text: data.text || prev.text,
      button: data.button || prev.button,
    }));
  });

  useNuiEvent('hintUiHide', () => setVisible(false));

  return (
    <Box className={classes.wrapper}>
      <ScaleFade visible={visible}>
        <Box className={classes.container}>
          <Group spacing={12} className={classes.title}>
            <i className="fa-solid fa-spinner-third fa-spin"></i>
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
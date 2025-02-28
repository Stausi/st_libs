import React from 'react';
import { Box, createStyles, Text } from '@mantine/core';
import { useNuiEvent } from '../../hooks/useNuiEvent';
import { fetchNui } from '../../utils/fetchNui';
import ScaleFade from '../../transitions/ScaleFade';
import type { ProgressbarProps } from '../../typings';

const useStyles = createStyles((theme) => {
  const barColor = theme.colors[theme.primaryColor][theme.fn.primaryShade()];
  
  const lightenColor = (hex: string, percent: number): string => {
    const num = parseInt(hex.slice(1), 16);
    const r = Math.min(255, (num >> 16) + (255 * percent));
    const g = Math.min(255, ((num >> 8) & 0x00FF) + (255 * percent));
    const b = Math.min(255, (num & 0x0000FF) + (255 * percent));
    return `rgba(${r}, ${g}, ${b}, 0.9)`;
  };

  const glowColor = lightenColor(barColor, 0.3);

  return {
    wrapper: {
      background: "transparent",
      margin: 0,
      padding: 0,
      overflow: 'hidden',
      width: '100%',
      height: '100%',
    },
    container: {
      zIndex: 5,
      color: '#fff',
      width: '19%',
      position: 'fixed',
      bottom: '5%',
      left: 0,
      right: 0,
      marginLeft: 'auto',
      marginRight: 'auto',
      fontSize: '1.7vh',
      fontFamily: '"Pathway Gothic One", sans-serif',
      fontStyle: 'normal',
    },
    labelWrapper: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
    },
    label: {
      fontSize: '1.7vh',
      lineHeight: '4vh',
      position: 'relative',
      color: theme.colors.gray[3],
      zIndex: 10,
      fontWeight: 'bold',
      textShadow: '1px 1px 3px rgba(0, 0, 0, 0.7)',
    },
    percentage: {
      fontSize: '1.7vh',
      lineHeight: '4vh',
      position: 'relative',
      color: theme.colors.gray[4],
      zIndex: 10,
      fontWeight: 'bold',
      textShadow: '1px 1px 3px rgba(0, 0, 0, 0.6)',
    },
    barContainer: {
      background: 'repeating-linear-gradient(135deg, #8286867e, #8286867e 1.4px, transparent 3px, transparent 4px)',
      height: '0.9vh',
      position: 'relative',
      display: 'block',
      borderRadius: '4px',
    },
    bar: {
      backgroundColor: barColor,
      width: '0%',
      height: '0.9vh',
      borderRadius: '4px',
      transition: 'width 0.3s ease-out',
      boxShadow: `0px 0px 20px ${glowColor}`,
      animation: 'flowEffect 1.5s infinite alternate ease-in-out',
    },
    '@keyframes flowEffect': {
      '0%': { boxShadow: `0px 0px 15px ${glowColor}` },
      '100%': { boxShadow: `0px 0px 40px ${glowColor}` },
    },
  };
});

const Progressbar: React.FC = () => {
  const { classes } = useStyles();
  const [visible, setVisible] = React.useState(false);
  const [label, setLabel] = React.useState('');
  const [duration, setDuration] = React.useState(0);
  const [value, setValue] = React.useState(0);

  useNuiEvent('progressCancel', () => setVisible(false));

  useNuiEvent<ProgressbarProps>('progress', (data) => {
    setVisible(true);
    setValue(0);
    
    setLabel(data.label);
    setDuration(data.duration);

    const onePercent = data.duration * 0.01;
    const updateProgress = setInterval(() => {
      setValue((previousValue) => {
        const newValue = previousValue + 1;
        newValue >= 100 && clearInterval(updateProgress);
        return newValue;
      });
    }, onePercent);
  });

  return (
    <>
      <Box className={classes.wrapper}>
        <ScaleFade visible={visible} onExitComplete={() => fetchNui('progressComplete')}>
          <Box className={classes.container}>
            <Box className={classes.labelWrapper}>
              <Text className={classes.label}>{label}</Text>
              <Text className={classes.percentage}>{value}%</Text>
            </Box>
            <Box className={classes.barContainer}>
              <Box
                className={classes.bar}
                onAnimationEnd={() => setVisible(false)}
                sx={{
                  animation: 'progress-bar linear',
                  animationDuration: `${duration}ms`,
                }}
              >
              </Box>
            </Box>
          </Box>
        </ScaleFade>
      </Box>
    </>
  );
};

export default Progressbar;
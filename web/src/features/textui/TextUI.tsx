import React, { useState, useEffect } from 'react';
import { Box, Text, createStyles, Transition } from '@mantine/core';
import { useNuiEvent } from '../../hooks/useNuiEvent';

const useStyles = createStyles((theme) => ({
  textUI: {
    width: 'fit-content',
    height: '4%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'row',
    position: 'absolute',
    bottom: '4%',
    left: 0,
    right: 0,
    margin: 'auto',
    fontFamily: 'Barlow, sans-serif',
    fontWeight: 450,
    gap: '0.5vw',
  },
  keyDiv: {
    width: 'fit-content',
    height: '100%',
    position: 'relative',
    padding: '0.3vw 0.35vw',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    color: '#08c098',
    background: '#171A21',
    borderRadius: 7,
  },
  keyDivInside: {
    width: '80%',
    height: '67%',
    position: 'relative',
    borderRadius: 4,
    border: '1px solid #08C098',
    background: 'rgba(8, 192, 152, 0.14)',
    boxShadow: '0px 0px 7.4px 1px rgba(8, 192, 152, 0.21)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    padding: '0.6vw',
    fontSize: '0.8vw',
    fontFamily: 'Inter, sans-serif',
    fontWeight: 500,
  },
  textContainer: {
    width: 'fit-content',
    height: '100%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
    padding: '0 1.9vw',
    color: '#A5A6AD',
    textShadow: '0px 0px 15px rgba(165, 166, 173, 0.45)',
    background: '#171A21',
    borderRadius: 4,
    whiteSpace: 'nowrap',
    overflow: 'hidden',
    fontSize: '0.8vw',
  },
  indicator: {
    width: 'fit-content',
    padding: '0.2vw',
    height: '18%',
    position: 'absolute',
    top: '14%',
    left: '5%',
    borderRadius: '0.833px',
    background: '#08C098',
    boxShadow: '0px 0px 3.2px 1px rgba(8, 192, 152, 0.37)',
  },
}));

const TextUI = () => {
  const { classes } = useStyles();
  const [visible, setVisible] = useState(false);
  const [keyText, setKeyText] = useState('');
  const [displayText, setDisplayText] = useState('');
  const [hideKey, setHideKey] = useState(false);

  useNuiEvent('textUI', (data) => {
    if (data.show) {
      setKeyText(data.key);
      setDisplayText(data.text);
      setVisible(true);
      setHideKey(data.hide || false);
    } else {
      setVisible(false);
    }
  });

  useNuiEvent('textUIUpdate', (data) => {
    setKeyText(data.key);
    setDisplayText(data.text);
  });

  return (
    <Transition mounted={visible} transition="pop" duration={800} timingFunction="ease">
      {(styles) => (
        <Box className={classes.textUI} style={styles}>
          {!hideKey && (
            <Box className={classes.keyDiv}>
              <Box className={classes.keyDivInside}>{keyText}</Box>
            </Box>
          )}
          <Box className={classes.textContainer}>
            <Box className={classes.indicator} />
            <Text>{displayText}</Text>
          </Box>
        </Box>
      )}
    </Transition>
  );
};

export default TextUI;
import { useState, useMemo } from 'react';
import { Box, Text, createStyles, Transition, keyframes } from '@mantine/core';
import { useNuiEvent } from '../../hooks/useNuiEvent';
import type { TextUiProps as BaseTextUiProps, TextUiPosition } from '../../typings';

type TextUiEntry = BaseTextUiProps & {
  id: string;
  position?: TextUiPosition;
};

type TextUiMessage = {
  entries?: TextUiEntry[];
};

const glow = keyframes({
  '0%':   { boxShadow: '0 0 3px 1px rgba(8,192,152,0.35)' },
  '50%':  { boxShadow: '0 0 14px 5px rgba(8,192,152,0.7)' },
  '100%': { boxShadow: '0 0 3px 1px rgba(8,192,152,0.35)' },
});

const useStyles = createStyles(() => ({
  wrapper: {
    height: '100%',
    width: '100%',
    position: 'absolute',
    display: 'flex',
    pointerEvents: 'none',
    top: 0,
    left: 0,
    zIndex: 2147483647,
  },

  stack: {
    display: 'flex',
    flexDirection: 'column',
    gap: '0.4vw',
    pointerEvents: 'none',
  },

  textUI: {
    width: 'fit-content',
    height: '40px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'row',
    gap: '0.5vw',
    fontFamily: 'Barlow, sans-serif',
    fontWeight: 450,
    pointerEvents: 'auto',
  },

  keyDiv: {
    width: 'fit-content',
    height: '100%',
    aspectRatio: '1 / 1',
    position: 'relative',
    padding: '0.5vw',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    color: '#08c098',
    backgroundColor: '#0f1114',
    border: '1px solid #2a2d31',
    boxShadow: 'inset 0 0 40px 10px rgba(16, 16, 18, 1), 0 4px 12px rgba(0, 0, 0, .3)',
  },

  keyDivInside: {
    width: '100%',
    height: '100%',
    position: 'relative',
    borderRadius: 4,
    border: '1px solid #08C098',
    background: 'rgba(8, 192, 152, 0.14)',
    boxShadow: '0px 0px 7.4px 1px rgba(8, 192, 152, 0.21)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    padding: '0.8vw',
    fontSize: '18px',
    fontFamily: 'Inter, sans-serif',
    fontWeight: 500,
    animation: `${glow} 1.8s ease-in-out infinite`,
  },

  textContainer: {
    minWidth: '120px',
    height: '100%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
    padding: '0 1.9vw',
    color: '#FFF',
    textShadow: '0px 0px 15px rgba(165, 166, 173, 0.45)',
    borderRadius: 4,
    whiteSpace: 'nowrap',
    overflow: 'hidden',
    fontSize: '18px',
    backgroundColor: '#0f1114',
    border: '1px solid #2a2d31',
    boxShadow: 'inset 0 0 40px 10px rgba(16, 16, 18, 1), 0 4px 12px rgba(0, 0, 0, .3)',
  },
}));

const getWrapperPositionStyle = (pos: TextUiPosition) => {
  switch (pos) {
    case 'top-center':
      return {
        alignItems: 'baseline',
        justifyContent: 'center',
        paddingTop: '4%',
      } as const;
    case 'bottom-center':
      return {
        alignItems: 'flex-end',
        justifyContent: 'center',
        paddingBottom: '4%',
      } as const;
    case 'left-center':
      return {
        alignItems: 'center',
        justifyContent: 'flex-start',
        paddingLeft: '2%',
      } as const;
    case 'right-center':
      return {
        alignItems: 'center',
        justifyContent: 'flex-end',
        paddingRight: '2%',
      } as const;
    default:
      return {
        alignItems: 'flex-end',
        justifyContent: 'center',
        paddingBottom: '4%',
      } as const;
  }
};

const DEFAULT_POSITION: TextUiPosition = 'bottom-center';

const TextUI = () => {
  const [visible, setVisible] = useState(false);
  const [entries, setEntries] = useState<TextUiEntry[]>([]);

  const { classes } = useStyles();

  useNuiEvent<TextUiMessage>('textUI', (data) => {
    const list = data.entries ?? [];
    setEntries(list);
    setVisible(list.length > 0);
  });

  const groupedByPosition = useMemo(() => {
    const groups: Record<TextUiPosition, TextUiEntry[]> = {
      'top-center': [],
      'bottom-center': [],
      'left-center': [],
      'right-center': [],
    };

    for (const entry of entries) {
      const pos = entry.position ?? DEFAULT_POSITION;
      groups[pos].push(entry);
    }

    (Object.keys(groups) as TextUiPosition[]).forEach((pos) => {
      if (groups[pos].length === 0) {
        delete groups[pos];
      }
    });

    return groups;
  }, [entries]);

  return (
    <Transition mounted={visible} transition="pop" duration={800} timingFunction="ease">
      {(styles) => (
        <>
          {Object.entries(groupedByPosition).map(([pos, group]) => {
            const position = pos as TextUiPosition;
            const wrapperPosStyle = getWrapperPositionStyle(position);

            return (
              <Box
                key={position}
                className={classes.wrapper}
                style={{ ...styles, ...wrapperPosStyle }}
              >
                <Box className={classes.stack}>
                  {group.map((entry) => (
                    <Box key={entry.id} className={classes.textUI}>
                      {!entry.hideKey && entry.keyText && (
                        <Box className={classes.keyDiv}>
                          <Box className={classes.keyDivInside}>{entry.keyText}</Box>
                        </Box>
                      )}
                      <Box className={classes.textContainer}>
                        <Text>{entry.displayText}</Text>
                      </Box>
                    </Box>
                  ))}
                </Box>
              </Box>
            );
          })}
        </>
      )}
    </Transition>
  );
};

export default TextUI;
import { Box, Typography } from '@mui/material';
import { Link, useLocation } from 'react-router-dom';
import { useColors } from '../hooks/useColors';
import { tokens } from '../tokens';

const NAV_HEIGHT = 60;

export default function AppShell({ children }: { children: React.ReactNode }) {
  const location = useLocation();
  const colors = useColors();
  const onChallenges = location.pathname.startsWith('/challenges');

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        backgroundColor: colors.bg,
      }}
    >
      <Box
        component="nav"
        sx={{
          height: NAV_HEIGHT,
          display: 'flex',
          alignItems: 'center',
          gap: 3,
          px: { xs: 2, md: 4 },
          borderBottom: `${tokens.border} solid ${tokens.color.edge}`,
          backgroundColor: colors.bg,
          position: 'sticky',
          top: 0,
          zIndex: 100,
        }}
      >
        <Typography
          component={Link}
          to="/"
          sx={{
            textDecoration: 'none',
            fontWeight: 800,
            fontSize: '1.25rem',
            color: colors.textPrimary,
            letterSpacing: '-0.04em',
          }}
        >
          LeetShaders
        </Typography>

        <Box sx={{ flex: 1 }} />

        <Typography
          component={Link}
          to="/challenges"
          aria-current={onChallenges ? 'page' : undefined}
          sx={{
            textDecoration: 'none',
            fontWeight: 600,
            fontSize: tokens.type.label.size,
            color: onChallenges ? colors.textPrimary : colors.textSecondary,
            minHeight: tokens.minTapTarget,
            display: 'inline-flex',
            alignItems: 'center',
            borderBottom: `${tokens.border} solid ${onChallenges ? tokens.color.red : 'transparent'}`,
            '&:hover': { color: colors.textPrimary },
          }}
        >
          Challenges
        </Typography>
      </Box>
      <Box sx={{ flex: 1 }}>{children}</Box>
    </Box>
  );
}

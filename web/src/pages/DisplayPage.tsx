import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { fetchDisplayBoard, type DisplayBoardOut } from '../api/client';

interface DisplayPageProps {
  officeId?: string;
}

export function DisplayPage({ officeId = 'ward-central-01' }: DisplayPageProps) {
  const { t } = useTranslation();
  const [board, setBoard] = useState<DisplayBoardOut | null>(null);
  const [currentTime, setCurrentTime] = useState<string>('');
  const [currentDate, setCurrentDate] = useState<string>('');
  const [error, setError] = useState<string | null>(null);
  const [isFullscreen, setIsFullscreen] = useState<boolean>(false);

  // Digital clock
  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setCurrentTime(
        now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true })
      );
      setCurrentDate(
        now.toLocaleDateString([], { weekday: 'long', year: 'numeric', month: 'short', day: 'numeric' })
      );
    };
    updateTime();
    const timer = setInterval(updateTime, 1000);
    return () => clearInterval(timer);
  }, []);

  // Poll display board every 3 seconds
  useEffect(() => {
    let mounted = true;

    const loadBoard = async () => {
      try {
        const data = await fetchDisplayBoard(officeId);
        if (mounted) {
          setBoard(data);
          setError(null);
        }
      } catch (err: unknown) {
        if (mounted) {
          console.error('Display board fetch error:', err);
          setError('Unable to connect to live queue board');
        }
      }
    };

    loadBoard();
    const interval = setInterval(loadBoard, 3000);
    return () => {
      mounted = false;
      clearInterval(interval);
    };
  }, [officeId]);

  const toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {});
      setIsFullscreen(true);
    } else {
      document.exitFullscreen().catch(() => {});
      setIsFullscreen(false);
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        backgroundColor: '#091322',
        color: '#f8fafc',
        display: 'flex',
        flexDirection: 'column',
        fontFamily: "'Noto Sans', sans-serif",
        padding: '24px 36px',
        boxSizing: 'border-box',
      }}
    >
      {/* Top Header */}
      <header
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          borderBottom: '2px solid rgba(255, 255, 255, 0.12)',
          paddingBottom: '20px',
          marginBottom: '28px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <span style={{ fontSize: '40px' }}>🏛️</span>
          <div>
            <h1 style={{ fontSize: '28px', fontWeight: 800, letterSpacing: '-0.5px', color: '#ffffff', margin: 0 }}>
              {board?.office_name || 'Ward Central Office'}
            </h1>
            <div style={{ fontSize: '15px', color: '#94a3b8', marginTop: '2px' }}>
              {t('display.subtitle')}
            </div>
          </div>
        </div>

        {/* Clock & Controls */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '24px' }}>
          <div style={{ textAlign: 'right' }}>
            <div
              style={{
                fontSize: '32px',
                fontWeight: 800,
                color: '#38bdf8',
                fontVariantNumeric: 'tabular-nums',
                letterSpacing: '1px',
              }}
            >
              {currentTime}
            </div>
            <div style={{ fontSize: '13px', color: '#94a3b8' }}>{currentDate}</div>
          </div>

          <button
            type="button"
            onClick={toggleFullscreen}
            style={{
              backgroundColor: 'rgba(255, 255, 255, 0.08)',
              border: '1px solid rgba(255, 255, 255, 0.2)',
              color: '#f8fafc',
              padding: '8px 16px',
              borderRadius: '8px',
              cursor: 'pointer',
              fontSize: '13px',
              fontWeight: 600,
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <span className="material-symbols-outlined" style={{ fontSize: '18px' }}>
              {isFullscreen ? 'fullscreen_exit' : 'fullscreen'}
            </span>
            {t('display.fullscreen_btn')}
          </button>
        </div>
      </header>

      {error && (
        <div
          style={{
            backgroundColor: '#7f1d1d',
            color: '#fecaca',
            padding: '12px 20px',
            borderRadius: '8px',
            marginBottom: '20px',
            fontSize: '14px',
            textAlign: 'center',
          }}
        >
          {error}
        </div>
      )}

      {/* Main Grid of Counters */}
      <main
        style={{
          flex: 1,
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
          gap: '24px',
          alignContent: 'start',
        }}
      >
        {board?.counters.map((c, idx) => {
          const isServing = Boolean(c.now_serving);
          return (
            <div
              key={idx}
              style={{
                backgroundColor: isServing ? '#0f243d' : '#0c1a2e',
                border: isServing ? '2px solid #0284c7' : '1px solid rgba(255, 255, 255, 0.1)',
                borderRadius: '16px',
                padding: '28px',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                textAlign: 'center',
                boxShadow: isServing ? '0 10px 30px -5px rgba(2, 132, 199, 0.3)' : 'none',
                transition: 'all 0.3s ease',
              }}
            >
              {/* Counter Label */}
              <div
                style={{
                  fontSize: '22px',
                  fontWeight: 800,
                  color: isServing ? '#bae6fd' : '#64748b',
                  letterSpacing: '1px',
                  textTransform: 'uppercase',
                  marginBottom: '12px',
                }}
              >
                {c.counter_label}
              </div>

              {/* Status Header */}
              <div
                style={{
                  fontSize: '14px',
                  fontWeight: 700,
                  letterSpacing: '2px',
                  textTransform: 'uppercase',
                  color: isServing ? '#38bdf8' : '#64748b',
                  marginBottom: '16px',
                }}
              >
                {isServing ? t('display.now_serving') : t('display.waiting')}
              </div>

              {/* Large Token Code */}
              <div
                style={{
                  fontSize: isServing ? '80px' : '44px',
                  fontWeight: 900,
                  color: isServing ? '#ffffff' : '#475569',
                  fontVariantNumeric: 'tabular-nums',
                  lineHeight: 1.1,
                  letterSpacing: '4px',
                  minHeight: '90px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                {c.now_serving || '—'}
              </div>
            </div>
          );
        })}
      </main>

      {/* Footer Ticker / Notice */}
      <footer
        style={{
          marginTop: '28px',
          borderTop: '1px solid rgba(255, 255, 255, 0.12)',
          paddingTop: '16px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          color: '#94a3b8',
          fontSize: '14px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span className="material-symbols-outlined" style={{ fontSize: '20px', color: '#38bdf8' }}>
            info
          </span>
          <span>{t('display.footer_notice')}</span>
        </div>
        <div style={{ fontSize: '12px', color: '#64748b' }}>
          QueueLess • Civic Queue Engine v3.0
        </div>
      </footer>
    </div>
  );
}

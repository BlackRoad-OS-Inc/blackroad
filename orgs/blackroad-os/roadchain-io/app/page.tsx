export default function Home() {
  return (
    <>
      {/* Navigation */}
      <nav style={{
        background: '#0a0a0a',
        borderBottom: '1px solid #2a2a2a',
        padding: '0 34px',
        height: '48px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '13px' }}>
          <a href="https://blackroad.io" style={{
            fontFamily: 'SF Mono, Fira Code, monospace',
            fontSize: '16px',
            fontWeight: 700,
            color: '#fff',
            textDecoration: 'none',
          }}>BlackRoad OS</a>
          <span style={{
            fontFamily: 'SF Mono, monospace',
            fontSize: '10px',
            color: '#555',
            background: '#1a1a1a',
            padding: '2px 8px',
            borderRadius: '3px',
          }}>v2.0</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span style={{
            width: '6px',
            height: '6px',
            borderRadius: '50%',
            background: '#4ade80',
          }} />
          <span style={{
            fontFamily: 'SF Mono, monospace',
            fontSize: '11px',
            color: '#555',
          }}>Operational</span>
        </div>
      </nav>

      {/* Main */}
      <main style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: 'calc(100vh - 120px)',
        padding: '89px 34px',
        textAlign: 'center',
      }}>
        <div style={{
          fontFamily: 'SF Mono, monospace',
          fontSize: '11px',
          color: '#555',
          background: '#1a1a1a',
          border: '1px solid #2a2a2a',
          padding: '5px 13px',
          borderRadius: '4px',
          marginBottom: '34px',
        }}>
          roadchain.io
        </div>

        <h1 style={{
          fontSize: '48px',
          fontWeight: 700,
          letterSpacing: '-1px',
          marginBottom: '21px',
          background: 'linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
        }}>
          RoadChain
        </h1>

        <p style={{
          fontSize: '18px',
          color: '#777',
          maxWidth: '560px',
          lineHeight: 1.618,
          marginBottom: '55px',
        }}>
          Decentralized infrastructure protocol for the sovereign web.
        </p>

        <div style={{ display: 'flex', gap: '13px' }}>
          <a href="https://blackroad.io" style={{
            fontFamily: 'SF Mono, monospace',
            fontSize: '13px',
            padding: '13px 34px',
            borderRadius: '6px',
            textDecoration: 'none',
            fontWeight: 500,
            background: '#fff',
            color: '#000',
          }}>
            Explore BlackRoad OS
          </a>
          <a href="https://github.com/BlackRoad-OS/roadchain-io" style={{
            fontFamily: 'SF Mono, monospace',
            fontSize: '13px',
            padding: '13px 34px',
            borderRadius: '6px',
            textDecoration: 'none',
            fontWeight: 500,
            background: 'transparent',
            color: '#777',
            border: '1px solid #2a2a2a',
          }}>
            View Source
          </a>
        </div>

        {/* Stats */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(3, 1fr)',
          gap: '1px',
          background: '#2a2a2a',
          marginTop: '89px',
          maxWidth: '600px',
          width: '100%',
        }}>
          {[
            { label: 'REPOS', value: '200+' },
            { label: 'DOMAINS', value: '20' },
            { label: 'AI AGENTS', value: '∞' },
          ].map((stat) => (
            <div key={stat.label} style={{
              background: '#111',
              padding: '34px',
              textAlign: 'left',
            }}>
              <div style={{
                fontFamily: 'SF Mono, monospace',
                fontSize: '11px',
                color: '#555',
                marginBottom: '8px',
              }}>{stat.label}</div>
              <div style={{ fontSize: '24px', fontWeight: 600 }}>{stat.value}</div>
            </div>
          ))}
        </div>
      </main>

      {/* Footer */}
      <footer style={{
        background: '#0a0a0a',
        borderTop: '1px solid #2a2a2a',
        padding: '21px 34px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
      }}>
        <span style={{
          fontFamily: 'SF Mono, monospace',
          fontSize: '11px',
          color: '#555',
        }}>© 2026 BlackRoad OS, Inc.</span>
        <div style={{ display: 'flex', gap: '21px' }}>
          {['Privacy', 'Terms', 'GitHub'].map((link) => (
            <a key={link} href="#" style={{
              fontFamily: 'SF Mono, monospace',
              fontSize: '11px',
              color: '#555',
              textDecoration: 'none',
            }}>{link}</a>
          ))}
        </div>
      </footer>
    </>
  )
}

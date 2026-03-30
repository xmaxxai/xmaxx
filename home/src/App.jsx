import './index.css'

const manifesto = [
  {
    value: '24/7',
    label: 'Autonomous operation without hand-holding',
  },
  {
    value: '<60s',
    label: 'From signal to action across your runtime stack',
  },
  {
    value: '∞',
    label: 'Room for agents, workloads, and new surfaces',
  },
]

const systems = [
  {
    title: 'Orchestrated Intelligence',
    body: 'Every model, workflow, and service is composed into one operational fabric instead of a pile of disconnected tools.',
  },
  {
    title: 'Human Override',
    body: 'Automation is aggressive, but never opaque. Operators can step in, audit decisions, and redirect execution instantly.',
  },
  {
    title: 'Deployment Velocity',
    body: 'From inference endpoints to front-end surfaces, the system is built to ship fast and keep moving under load.',
  },
]

const lanes = [
  'AI-native product surfaces',
  'Operational control planes',
  'Realtime service orchestration',
  'Design systems with actual taste',
]

function App() {
  return (
    <main className="page-shell">
      <section className="hero-grid">
        <div className="hero-copy">
          <p className="eyebrow">XMAXX</p>
          <h1>AI systems with a pulse, not another static brochure.</h1>
          <p className="lede">
            XMAXX builds sharp, high-output digital infrastructure for teams
            that want intelligent software, decisive execution, and interfaces
            that feel alive the moment they load.
          </p>
          <div className="cta-row">
            <a className="primary-cta" href="#signal">
              Enter The System
            </a>
            <a className="secondary-cta" href="#blueprint">
              View Blueprint
            </a>
          </div>
        </div>

        <div className="hero-panel">
          <div className="hero-panel__header">
            <span>Live stack</span>
            <span>React • K3s • AWS</span>
          </div>
          <div className="signal-board" id="signal">
            <div className="signal-board__core">
              <span className="signal-ring signal-ring--outer" />
              <span className="signal-ring signal-ring--mid" />
              <span className="signal-ring signal-ring--inner" />
              <div className="signal-heart">
                <span>X</span>
              </div>
            </div>
            <div className="signal-board__copy">
              <p className="signal-tag">SYSTEM STATUS</p>
              <h2>Ready to amplify product, ops, and presence.</h2>
              <p>
                Precision-built web surfaces paired with deployable AI
                infrastructure. Clear enough to trust. Fast enough to compound.
              </p>
            </div>
          </div>
        </div>
      </section>

      <section className="metric-strip">
        {manifesto.map((item) => (
          <article key={item.label} className="metric-card">
            <p className="metric-value">{item.value}</p>
            <p className="metric-label">{item.label}</p>
          </article>
        ))}
      </section>

      <section className="blueprint" id="blueprint">
        <div className="section-heading">
          <p className="eyebrow">Blueprint</p>
          <h2>Built to hold pressure, attention, and velocity at once.</h2>
        </div>

        <div className="system-grid">
          {systems.map((system) => (
            <article key={system.title} className="system-card">
              <p className="system-index">{system.title}</p>
              <p>{system.body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="launch-rail">
        <div className="launch-rail__copy">
          <p className="eyebrow">Launch Lanes</p>
          <h2>Where XMAXX shows up.</h2>
        </div>
        <div className="launch-rail__track">
          {lanes.map((lane) => (
            <div key={lane} className="launch-pill">
              {lane}
            </div>
          ))}
        </div>
      </section>

      <section className="closing-banner">
        <div>
          <p className="eyebrow">Now Live</p>
          <h2>Designed to look premium. Engineered to actually deploy.</h2>
        </div>
        <a className="primary-cta" href="mailto:hello@xmaxx.ai">
          hello@xmaxx.ai
        </a>
      </section>
    </main>
  )
}

export default App

import { AnimatePresence, motion, useReducedMotion } from 'motion/react'
import { useEffect, useId, useState } from 'react'
import heroImage from './assets/hero.png'
import { AudienceMenu } from './components/AudienceMenu'
import { BriefModal } from './components/BriefModal'
import {
  InteractiveLink,
  InteractiveSurface,
  Reveal,
  SkeletonBlock,
  StaggerGroup,
  StaggerItem,
} from './components/motion-primitives'
import './index.css'

const navLinks = [
  { label: 'Platform', href: '#platform' },
  { label: 'Focus', href: '#focus' },
  { label: 'Stack', href: '#stack' },
]

const metrics = [
  {
    value: '24/7',
    label: 'Operator-aware automation, not passive dashboards.',
  },
  {
    value: '<60s',
    label: 'From signal to surfaced action across the runtime path.',
  },
  {
    value: '3X',
    label: 'Software, AI, and hardware designed as one system.',
  },
  {
    value: 'TLS',
    label: 'Production ingress, live cluster, and trusted HTTPS in motion.',
  },
]

const lenses = [
  {
    id: 'operators',
    label: 'Operators',
    description: 'Pressure-tested control',
    heading: 'Make the operating surface calm, legible, and fast under load.',
    body: 'Operators need interfaces that stay clear when conditions change. XMAXX emphasizes observability, override paths, and actions that can be trusted under pressure.',
  },
  {
    id: 'partners',
    label: 'Partners',
    description: 'Signal with business clarity',
    heading: 'Show external stakeholders a system that is credible, measurable, and integration-ready.',
    body: 'Partners and vendors need disciplined visibility into what is deployed, what can be integrated, and how value will be measured over time.',
  },
  {
    id: 'builders',
    label: 'Builders',
    description: 'Ship the platform cleanly',
    heading: 'Treat infrastructure, release flow, and UI polish as one engineering concern.',
    body: 'Builders need a stack that can move from local iteration to cluster delivery without turning deployment, motion, and accessibility into separate projects.',
  },
]

const capabilities = [
  {
    id: 'telemetry',
    title: 'Field telemetry',
    eyebrow: 'Signal plane',
    body: 'Translate water, air, environment, and equipment behavior into inputs the system can actually reason about.',
    scores: { operators: 95, partners: 72, builders: 82 },
  },
  {
    id: 'control',
    title: 'Operator control surfaces',
    eyebrow: 'Human override',
    body: 'Keep escalation, intervention, and auditability close to the interface rather than buried behind automation.',
    scores: { operators: 97, partners: 70, builders: 86 },
  },
  {
    id: 'delivery',
    title: 'Infrastructure that ships like a product',
    eyebrow: 'Platform delivery',
    body: 'Terraform, Docker, K3s, and Helm are treated as part of the product system, not back-office chores.',
    scores: { operators: 79, partners: 68, builders: 99 },
  },
  {
    id: 'partner',
    title: 'Partner-ready integration layers',
    eyebrow: 'External collaboration',
    body: 'Expose clean operational surfaces to vendors, partners, and future ecosystem collaborators without losing discipline.',
    scores: { operators: 61, partners: 96, builders: 74 },
  },
  {
    id: 'presence',
    title: 'Premium digital presence',
    eyebrow: 'Public interface',
    body: 'The public surface should look deliberate and perform with the same clarity as the systems behind it.',
    scores: { operators: 57, partners: 88, builders: 75 },
  },
  {
    id: 'hardware',
    title: 'Software-to-hardware loop',
    eyebrow: 'Physical systems',
    body: 'Use AI and software to shape how hardware senses, reports, and responds instead of treating devices as isolated endpoints.',
    scores: { operators: 91, partners: 84, builders: 89 },
  },
]

const stackLayers = [
  {
    title: 'Terraform',
    body: 'AWS networking, instance provisioning, load balancers, and security groups are managed as code so the platform stays reproducible.',
  },
  {
    title: 'K3s Cluster',
    body: 'The runtime is lightweight but real: ingress, workers, TLS automation, and app delivery run inside a live Kubernetes surface.',
  },
  {
    title: 'Docker',
    body: 'The `home` app is built into a portable image so the frontend ships as a deployable artifact, not a manual file transfer.',
  },
  {
    title: 'Helm',
    body: 'Release behavior, service rules, and ingress settings are captured in the chart so the site can evolve without cluster drift.',
  },
]

const proofPoints = [
  'AI surfaces for water, air, and environmental systems',
  'Operational control planes for teams under real constraints',
  'High-trust interfaces that still feel premium and modern',
]

function HeroPreview({ ready, onReady }) {
  const reduceMotion = useReducedMotion()

  return (
    <div className="hero-visual surface surface--dark">
      <div className="hero-visual__header">
        <span>Live surface</span>
        <span>React • Motion • Helm</span>
      </div>

      <div className="hero-visual__media">
        <AnimatePresence>
          {!ready ? (
            <motion.div
              key="skeleton"
              className="hero-visual__skeleton"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.22 }}
            >
              <SkeletonBlock className="hero-visual__skeleton-frame" />
              <div className="hero-visual__skeleton-copy">
                <SkeletonBlock className="hero-visual__skeleton-line hero-visual__skeleton-line--long" />
                <SkeletonBlock className="hero-visual__skeleton-line" />
                <SkeletonBlock className="hero-visual__skeleton-line hero-visual__skeleton-line--short" />
              </div>
            </motion.div>
          ) : null}
        </AnimatePresence>

        <motion.img
          className="hero-visual__image"
          src={heroImage}
          alt="Abstract XMAXX system composition showing layered environmental and digital structure."
          initial={false}
          animate={{ opacity: ready ? 1 : 0, scale: ready ? 1 : 1.03 }}
          transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
          onLoad={onReady}
        />

        <motion.div
          className="hero-badge hero-badge--top"
          animate={
            reduceMotion ? undefined : { y: [0, -6, 0], rotate: [0, -1, 0] }
          }
          transition={
            reduceMotion
              ? undefined
              : { duration: 5.6, repeat: Number.POSITIVE_INFINITY, ease: 'easeInOut' }
          }
        >
          ACME-secured HTTPS
        </motion.div>
        <motion.div
          className="hero-badge hero-badge--bottom"
          animate={reduceMotion ? undefined : { y: [0, 8, 0] }}
          transition={
            reduceMotion
              ? undefined
              : { duration: 6.2, repeat: Number.POSITIVE_INFINITY, ease: 'easeInOut' }
          }
        >
          Runtime-ready infrastructure
        </motion.div>
      </div>

      <div className="hero-visual__footer">
        <div>
          <p className="hero-visual__label">Stack posture</p>
          <strong>Production-minded from day one</strong>
        </div>
        <p>
          The public surface is already backed by a live cluster, load-balanced
          ingress, and persisted certificate automation.
        </p>
      </div>
    </div>
  )
}

function App() {
  const [activeLens, setActiveLens] = useState('operators')
  const [isBriefOpen, setIsBriefOpen] = useState(false)
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [heroReady, setHeroReady] = useState(false)
  const menuId = useId()

  useEffect(() => {
    if (!isMenuOpen) {
      return undefined
    }

    const handleKeyDown = (event) => {
      if (event.key === 'Escape') {
        setIsMenuOpen(false)
      }
    }

    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    window.addEventListener('keydown', handleKeyDown)

    return () => {
      document.body.style.overflow = previousOverflow
      window.removeEventListener('keydown', handleKeyDown)
    }
  }, [isMenuOpen])

  const rankedCapabilities = [...capabilities].sort(
    (left, right) => right.scores[activeLens] - left.scores[activeLens],
  )
  const activeLensData =
    lenses.find((lens) => lens.id === activeLens) ?? lenses[0]

  return (
    <>
      <main className="app-shell">
        <div className="ambient ambient--one" />
        <div className="ambient ambient--two" />

        <header className="topbar surface">
          <a className="brand" href="#top">
            <span>XMAXX</span>
            <small>software • hardware • AI</small>
          </a>

          <nav className="topnav" aria-label="Primary">
            {navLinks.map((link) => (
              <InteractiveLink key={link.href} className="topnav__link" href={link.href}>
                {link.label}
              </InteractiveLink>
            ))}
          </nav>

          <div className="topbar__actions">
            <AudienceMenu
              activeValue={activeLens}
              onSelect={setActiveLens}
              options={lenses}
            />
            <InteractiveLink
              as={motion.button}
              type="button"
              className="button button--solid button--small"
              onClick={() => setIsBriefOpen(true)}
            >
              Operator brief
            </InteractiveLink>
          </div>

          <InteractiveLink
            as={motion.button}
            type="button"
            className="menu-toggle"
            aria-controls={menuId}
            aria-expanded={isMenuOpen}
            onClick={() => setIsMenuOpen(true)}
          >
            Menu
          </InteractiveLink>
        </header>

        <Reveal as={motion.section} className="hero section surface" id="top">
          <div className="hero-copy">
            <p className="eyebrow">XMAXX / live systems</p>
            <h1>We maxx the systems that shape how people live.</h1>
            <p className="hero-copy__lede">
              From water and air to infrastructure, interfaces, and physical
              environments, XMAXX builds AI-enabled software and hardware
              systems designed to see more, decide faster, and improve what is
              underperforming.
            </p>

            <div className="hero-copy__actions">
              <InteractiveLink
                as={motion.button}
                type="button"
                className="button button--solid"
                onClick={() => setIsBriefOpen(true)}
              >
                Book a build conversation
              </InteractiveLink>
              <InteractiveLink className="button button--ghost" href="#focus">
                Explore the focus deck
              </InteractiveLink>
            </div>

            <ul className="proof-list" aria-label="XMAXX proof points">
              {proofPoints.map((item) => (
                <motion.li
                  key={item}
                  className="proof-list__item"
                  initial={{ opacity: 0, x: -14 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true, amount: 0.6 }}
                  transition={{ duration: 0.48 }}
                >
                  <span className="proof-list__dot" />
                  {item}
                </motion.li>
              ))}
            </ul>
          </div>

          <HeroPreview ready={heroReady} onReady={() => setHeroReady(true)} />
        </Reveal>

        <StaggerGroup as={motion.section} className="metric-strip" id="platform">
          {metrics.map((item) => (
            <StaggerItem key={item.label}>
              <InteractiveSurface className="metric-card" lift={5}>
                <p className="metric-card__value">{item.value}</p>
                <p className="metric-card__label">{item.label}</p>
              </InteractiveSurface>
            </StaggerItem>
          ))}
        </StaggerGroup>

        <Reveal as={motion.section} className="focus section" id="focus">
          <div className="section-copy">
            <p className="eyebrow">Audience focus</p>
            <h2>One system, different priorities depending on who is in the room.</h2>
            <p>
              The same platform should read differently to operators, partners,
              and builders. Change the lens and the capability deck reorders
              around what matters most.
            </p>
          </div>

          <div className="lens-bar">
            <div className="lens-tabs" role="tablist" aria-label="Audience lenses">
              {lenses.map((lens) => (
                <motion.button
                  key={lens.id}
                  type="button"
                  className={`lens-tab${lens.id === activeLens ? ' lens-tab--active' : ''}`}
                  onClick={() => setActiveLens(lens.id)}
                  role="tab"
                  aria-selected={lens.id === activeLens}
                  layout
                >
                  {lens.id === activeLens ? (
                    <motion.span
                      className="lens-tab__pill"
                      layoutId="active-lens"
                      transition={{ duration: 0.32, ease: [0.22, 1, 0.36, 1] }}
                    />
                  ) : null}
                  <span className="lens-tab__label">{lens.label}</span>
                </motion.button>
              ))}
            </div>

            <p className="lens-bar__note">
              Layout shifts are intentional here: the deck re-prioritizes as the
              audience changes.
            </p>
          </div>

          <motion.div layout className="lens-summary surface">
            <AnimatePresence mode="wait">
              <motion.div
                key={activeLens}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.24 }}
              >
                <p className="eyebrow">{activeLensData.description}</p>
                <h3>{activeLensData.heading}</h3>
                <p>{activeLensData.body}</p>
              </motion.div>
            </AnimatePresence>
          </motion.div>

          <motion.div layout className="capability-grid">
            {rankedCapabilities.map((item, index) => (
              <InteractiveSurface
                as={motion.article}
                layout
                key={item.id}
                className={`capability-card${
                  index < 2 ? ' capability-card--featured' : ''
                }`}
                lift={6}
              >
                <div className="capability-card__head">
                  <p className="capability-card__eyebrow">{item.eyebrow}</p>
                  <span className="capability-card__score">
                    {item.scores[activeLens]}
                  </span>
                </div>
                <h3>{item.title}</h3>
                <p>{item.body}</p>
                <div className="capability-card__meter" aria-hidden="true">
                  <motion.span
                    className="capability-card__meter-fill"
                    initial={false}
                    animate={{ width: `${item.scores[activeLens]}%` }}
                    transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
                  />
                </div>
              </InteractiveSurface>
            ))}
          </motion.div>
        </Reveal>

        <StaggerGroup as={motion.section} className="stack section" id="stack">
          <div className="section-copy section-copy--tight">
            <p className="eyebrow">Platform stack</p>
            <h2>Built to look premium and deploy like software.</h2>
            <p>
              The UI is only credible if the delivery path is credible. The
              current platform already connects infrastructure-as-code,
              containerized delivery, cluster runtime, and ingress automation.
            </p>
          </div>

          <div className="stack-grid">
            {stackLayers.map((layer) => (
              <StaggerItem key={layer.title}>
                <InteractiveSurface className="stack-card" lift={5}>
                  <p className="stack-card__title">{layer.title}</p>
                  <p>{layer.body}</p>
                </InteractiveSurface>
              </StaggerItem>
            ))}
          </div>
        </StaggerGroup>

        <Reveal as={motion.section} className="closing-banner surface surface--dark">
          <div className="closing-banner__copy">
            <p className="eyebrow">MAXXER posture</p>
            <h2>Build the software. Build the hardware. Maxx the system end to end.</h2>
            <p>
              XMAXX is aiming at systems that can be measured, improved, and
              continuously refined with AI. The website is the first public
              surface, not the endpoint.
            </p>
          </div>

          <div className="closing-banner__actions">
            <InteractiveLink
              as={motion.button}
              type="button"
              className="button button--solid button--contrast"
              onClick={() => setIsBriefOpen(true)}
            >
              Start the conversation
            </InteractiveLink>
            <InteractiveLink className="button button--ghost button--contrast" href="mailto:info@xmaxx.ai">
              info@xmaxx.ai
            </InteractiveLink>
          </div>
        </Reveal>
      </main>

      <AnimatePresence>
        {isMenuOpen ? (
          <motion.div
            className="overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={() => setIsMenuOpen(false)}
          >
            <motion.aside
              id={menuId}
              className="mobile-panel surface"
              initial={{ x: '100%', opacity: 0.96 }}
              animate={{ x: 0, opacity: 1 }}
              exit={{ x: '100%', opacity: 0.96 }}
              transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
              onClick={(event) => event.stopPropagation()}
            >
              <div className="mobile-panel__header">
                <div>
                  <p className="eyebrow">Navigate</p>
                  <h2>Move through the surface cleanly.</h2>
                </div>
                <button
                  type="button"
                  className="icon-button"
                  onClick={() => setIsMenuOpen(false)}
                  aria-label="Close menu"
                >
                  ×
                </button>
              </div>

              <div className="mobile-panel__links">
                {navLinks.map((link) => (
                  <InteractiveLink
                    key={link.href}
                    className="mobile-link"
                    href={link.href}
                    onClick={() => setIsMenuOpen(false)}
                  >
                    {link.label}
                  </InteractiveLink>
                ))}
              </div>

              <div className="mobile-panel__lenses">
                <p className="eyebrow">Audience lens</p>
                <div className="mobile-panel__chips">
                  {lenses.map((lens) => (
                    <motion.button
                      key={lens.id}
                      type="button"
                      className={`mobile-chip${
                        activeLens === lens.id ? ' mobile-chip--active' : ''
                      }`}
                      onClick={() => {
                        setActiveLens(lens.id)
                        setIsMenuOpen(false)
                      }}
                      whileTap={{ scale: 0.98 }}
                    >
                      {lens.label}
                    </motion.button>
                  ))}
                </div>
              </div>

              <InteractiveLink
                as={motion.button}
                type="button"
                className="button button--solid"
                onClick={() => {
                  setIsMenuOpen(false)
                  setIsBriefOpen(true)
                }}
              >
                Request operator brief
              </InteractiveLink>
            </motion.aside>
          </motion.div>
        ) : null}
      </AnimatePresence>

      <BriefModal open={isBriefOpen} onClose={() => setIsBriefOpen(false)} />
    </>
  )
}

export default App

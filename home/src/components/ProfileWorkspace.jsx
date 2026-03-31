import { motion } from 'motion/react'
import { useEffect, useState } from 'react'
import { Reveal, SkeletonBlock } from './motion-primitives'

const emptyFieldErrors = {}

const previewFields = [
  { key: 'headline', label: 'Headline' },
  { key: 'company', label: 'Company' },
  { key: 'location', label: 'Location' },
  { key: 'websiteUrl', label: 'Website' },
]

function buildEmptyProfileForm(authState) {
  return {
    displayName: authState.user?.name ?? '',
    headline: '',
    bio: '',
    location: '',
    company: '',
    websiteUrl: '',
  }
}

function buildProfileForm(profile, authState) {
  if (!profile) {
    return buildEmptyProfileForm(authState)
  }

  return {
    displayName: profile.displayName ?? '',
    headline: profile.headline ?? '',
    bio: profile.bio ?? '',
    location: profile.location ?? '',
    company: profile.company ?? '',
    websiteUrl: profile.websiteUrl ?? '',
  }
}

function parseApiError(response, payload) {
  const error = new Error(
    payload.detail || payload.messages?.[0] || `Request failed with status ${response.status}`,
  )
  error.status = response.status
  error.payload = payload
  return error
}

async function parseJsonResponse(response) {
  const text = await response.text()

  if (!text) {
    return {}
  }

  try {
    return JSON.parse(text)
  } catch {
    return {}
  }
}

function readCookie(name) {
  if (typeof document === 'undefined') {
    return ''
  }

  const prefix = `${name}=`

  for (const part of document.cookie.split(';')) {
    const cookie = part.trim()

    if (cookie.startsWith(prefix)) {
      return decodeURIComponent(cookie.slice(prefix.length))
    }
  }

  return ''
}

async function requestProfile(signal) {
  const response = await fetch('/api/profile/', {
    credentials: 'same-origin',
    headers: { Accept: 'application/json' },
    signal,
  })
  const payload = await parseJsonResponse(response)

  if (!response.ok) {
    throw parseApiError(response, payload)
  }

  return payload
}

async function writeProfile(method, profile) {
  const csrfToken = readCookie('csrftoken')
  const headers = {
    Accept: 'application/json',
    'Content-Type': 'application/json',
  }

  if (csrfToken) {
    headers['X-CSRFToken'] = csrfToken
  }

  const response = await fetch('/api/profile/', {
    method,
    credentials: 'same-origin',
    headers,
    body: method === 'DELETE' ? undefined : JSON.stringify(profile),
  })
  const payload = await parseJsonResponse(response)

  if (!response.ok) {
    throw parseApiError(response, payload)
  }

  return payload
}

async function requestAccessTokens(signal) {
  const response = await fetch('/api/tokens/', {
    credentials: 'same-origin',
    headers: { Accept: 'application/json' },
    signal,
  })
  const payload = await parseJsonResponse(response)

  if (!response.ok) {
    throw parseApiError(response, payload)
  }

  return payload
}

async function createAccessToken(name) {
  const csrfToken = readCookie('csrftoken')
  const headers = {
    Accept: 'application/json',
    'Content-Type': 'application/json',
  }

  if (csrfToken) {
    headers['X-CSRFToken'] = csrfToken
  }

  const response = await fetch('/api/tokens/', {
    method: 'POST',
    credentials: 'same-origin',
    headers,
    body: JSON.stringify({ name }),
  })
  const payload = await parseJsonResponse(response)

  if (!response.ok) {
    throw parseApiError(response, payload)
  }

  return payload
}

async function revokeAccessToken(tokenKey) {
  const csrfToken = readCookie('csrftoken')
  const headers = {
    Accept: 'application/json',
  }

  if (csrfToken) {
    headers['X-CSRFToken'] = csrfToken
  }

  const response = await fetch(`/api/tokens/${encodeURIComponent(tokenKey)}/`, {
    method: 'DELETE',
    credentials: 'same-origin',
    headers,
  })
  const payload = await parseJsonResponse(response)

  if (!response.ok) {
    throw parseApiError(response, payload)
  }

  return payload
}

function getProviderLabel(authState) {
  if (authState.provider === 'github') {
    return 'GitHub'
  }

  if (authState.provider === 'google') {
    return 'Google'
  }

  return 'OAuth'
}

function getIdentityLabel(authState) {
  const providerLabel = getProviderLabel(authState)

  if (authState.provider === 'github' && authState.user?.login) {
    return `${providerLabel} • @${authState.user.login}`
  }

  if (authState.user?.email) {
    return `${providerLabel} • ${authState.user.email}`
  }

  if (authState.user?.login) {
    return `${providerLabel} • ${authState.user.login}`
  }

  return providerLabel
}

function getProfileInitial(form, authState) {
  const seed =
    form.displayName ||
    authState.user?.name ||
    authState.user?.email ||
    authState.user?.login ||
    'P'

  return seed.slice(0, 1).toUpperCase()
}

function getUserInitial(authState) {
  const seed =
    authState.user?.name || authState.user?.email || authState.user?.login || 'O'

  return seed.slice(0, 1).toUpperCase()
}

function formatTimestamp(timestamp) {
  if (!timestamp) {
    return 'Not saved yet'
  }

  const value = new Date(timestamp)

  if (Number.isNaN(value.getTime())) {
    return 'Not saved yet'
  }

  return value.toLocaleString()
}

function formatFieldValue(key, value) {
  if (!value) {
    return 'Not set'
  }

  if (key === 'websiteUrl') {
    return value.replace(/^https?:\/\//, '')
  }

  return value
}

function formatLastUsed(timestamp) {
  if (!timestamp) {
    return 'Never used'
  }

  return formatTimestamp(timestamp)
}

function SignInRequired({ copy, onOpenLogin }) {
  return (
    <div className="profile-empty">
      <p>{copy}</p>
      <motion.button
        type="button"
        className="button button--solid"
        onClick={onOpenLogin}
        whileTap={{ scale: 0.985 }}
      >
        Choose sign-in
      </motion.button>
    </div>
  )
}

function ProfileIdentityCard({ authState, form, profile, isAuthenticated }) {
  return (
    <aside className="profile-preview surface surface--dark">
      <div className="profile-preview__identity">
        {authState.user?.avatar_url ? (
          <img
            className="profile-preview__avatar"
            src={authState.user.avatar_url}
            alt={`${form.displayName || authState.user.name || 'Operator'} avatar`}
          />
        ) : (
          <span className="profile-preview__avatar profile-preview__avatar--fallback">
            {getProfileInitial(form, authState)}
          </span>
        )}

        <div className="profile-preview__copy">
          <p className="eyebrow">Session identity</p>
          <h3>{form.displayName || 'Operator profile'}</h3>
          <small>{isAuthenticated ? getIdentityLabel(authState) : 'Sign-in required'}</small>
        </div>
      </div>

      <p className="profile-preview__bio">
        {form.bio ||
          'Use this page to define the backend record tied to the signed-in operator account.'}
      </p>

      <dl className="profile-preview__facts">
        {previewFields.map((field) => (
          <div key={field.key} className="profile-preview__fact">
            <dt>{field.label}</dt>
            <dd>{formatFieldValue(field.key, form[field.key])}</dd>
          </div>
        ))}
      </dl>

      <div className="profile-preview__meta">
        <span>Created: {formatTimestamp(profile?.createdAt)}</span>
        <span>Updated: {formatTimestamp(profile?.updatedAt)}</span>
      </div>
    </aside>
  )
}

function TokenIdentityCard({ authState, tokens, revealedToken, isAuthenticated }) {
  const activeTokenCount = tokens.filter((token) => token.status === 'active').length

  return (
    <aside className="profile-preview surface surface--dark">
      <div className="profile-preview__identity">
        {authState.user?.avatar_url ? (
          <img
            className="profile-preview__avatar"
            src={authState.user.avatar_url}
            alt={`${authState.user.name || 'Operator'} avatar`}
          />
        ) : (
          <span className="profile-preview__avatar profile-preview__avatar--fallback">
            {getUserInitial(authState)}
          </span>
        )}

        <div className="profile-preview__copy">
          <p className="eyebrow">Account scope</p>
          <h3>{isAuthenticated ? authState.user?.name || 'Operator' : 'API Access'}</h3>
          <small>{isAuthenticated ? getIdentityLabel(authState) : 'Sign-in required'}</small>
        </div>
      </div>

      <p className="profile-preview__bio">
        Bearer tokens belong to this signed-in account and can be generated, listed,
        and revoked from this page without touching the homepage.
      </p>

      <dl className="profile-preview__facts">
        <div className="profile-preview__fact">
          <dt>Active tokens</dt>
          <dd>{activeTokenCount}</dd>
        </div>
        <div className="profile-preview__fact">
          <dt>Total issued</dt>
          <dd>{tokens.length}</dd>
        </div>
        <div className="profile-preview__fact">
          <dt>Header format</dt>
          <dd>Authorization: Bearer xmaxx_xtk_...</dd>
        </div>
      </dl>

      {revealedToken ? (
        <div className="token-reveal__block">
          <span>Latest token</span>
          <code>{revealedToken.plainTextToken}</code>
        </div>
      ) : null}
    </aside>
  )
}

export function ProfilePage({ authState, onOpenLogin }) {
  const isAuthenticated = authState.authenticated && authState.user
  const [loading, setLoading] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [exists, setExists] = useState(false)
  const [profile, setProfile] = useState(null)
  const [form, setForm] = useState(() => buildEmptyProfileForm(authState))
  const [error, setError] = useState('')
  const [fieldErrors, setFieldErrors] = useState(emptyFieldErrors)
  const [notice, setNotice] = useState(null)

  useEffect(() => {
    if (!isAuthenticated) {
      setLoading(false)
      setSubmitting(false)
      setDeleting(false)
      setExists(false)
      setProfile(null)
      setForm(buildEmptyProfileForm(authState))
      setError('')
      setFieldErrors(emptyFieldErrors)
      setNotice(null)
      return undefined
    }

    const controller = new AbortController()

    setLoading(true)
    setError('')
    setFieldErrors(emptyFieldErrors)

    void requestProfile(controller.signal)
      .then((payload) => {
        if (controller.signal.aborted) {
          return
        }

        setExists(Boolean(payload.exists))
        setProfile(payload.profile ?? null)
        setForm(buildProfileForm(payload.profile, authState))
      })
      .catch((requestError) => {
        if (controller.signal.aborted) {
          return
        }

        setExists(false)
        setProfile(null)
        setForm(buildEmptyProfileForm(authState))
        setError(
          requestError instanceof Error
            ? requestError.message
            : 'Unable to load the saved profile.',
        )
      })
      .finally(() => {
        if (!controller.signal.aborted) {
          setLoading(false)
        }
      })

    return () => controller.abort()
  }, [authState, isAuthenticated])

  const handleFieldChange = (event) => {
    const { name, value } = event.target

    setForm((current) => ({ ...current, [name]: value }))
    setError('')

    setFieldErrors((current) => {
      if (!current[name]) {
        return current
      }

      const next = { ...current }
      delete next[name]
      return next
    })
  }

  const handleReset = () => {
    setForm(buildProfileForm(profile, authState))
    setError('')
    setFieldErrors(emptyFieldErrors)
    setNotice({
      tone: 'info',
      title: exists ? 'Changes discarded' : 'Draft cleared',
      body: exists
        ? 'The editor is back in sync with the saved backend record.'
        : 'The editor has been reset to a fresh draft for this signed-in user.',
    })
  }

  const handleSubmit = async (event) => {
    event.preventDefault()

    setSubmitting(true)
    setError('')
    setFieldErrors(emptyFieldErrors)
    setNotice(null)

    try {
      const payload = await writeProfile(exists ? 'PATCH' : 'POST', form)

      setExists(true)
      setProfile(payload.profile)
      setForm(buildProfileForm(payload.profile, authState))
      setNotice({
        tone: 'success',
        title: exists ? 'Profile updated' : 'Profile created',
        body: exists
          ? 'The backend profile record was updated and reloaded into the editor.'
          : 'The backend now has a saved profile record for this signed-in user.',
      })
    } catch (requestError) {
      const payload =
        requestError instanceof Error && 'payload' in requestError
          ? requestError.payload
          : {}

      setError(
        requestError instanceof Error
          ? requestError.message
          : 'Unable to save the profile.',
      )
      setFieldErrors(payload?.fields ?? emptyFieldErrors)
    } finally {
      setSubmitting(false)
    }
  }

  const handleDelete = async () => {
    if (!exists || deleting) {
      return
    }

    if (!window.confirm('Delete the saved profile for this signed-in user?')) {
      return
    }

    setDeleting(true)
    setError('')
    setFieldErrors(emptyFieldErrors)
    setNotice(null)

    try {
      await writeProfile('DELETE')
      setExists(false)
      setProfile(null)
      setForm(buildEmptyProfileForm(authState))
      setNotice({
        tone: 'info',
        title: 'Profile deleted',
        body: 'The saved backend record was removed. You can create a fresh profile at any time.',
      })
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : 'Unable to delete the profile.',
      )
    } finally {
      setDeleting(false)
    }
  }

  const statusClass = loading
    ? 'profile-badge profile-badge--muted'
    : exists
      ? 'profile-badge profile-badge--live'
      : isAuthenticated
        ? 'profile-badge profile-badge--warm'
        : 'profile-badge profile-badge--muted'
  const statusLabel = loading ? 'Loading' : exists ? 'Saved' : isAuthenticated ? 'Draft' : 'Locked'
  const submitLabel = submitting
    ? exists
      ? 'Saving changes...'
      : 'Creating profile...'
    : exists
      ? 'Save changes'
      : 'Create profile'

  return (
    <Reveal as={motion.section} className="profile-workspace section-block">
      <div className="section-heading">
        <p className="eyebrow">Profile</p>
        <h2>Manage the signed-in operator profile on its own page.</h2>
        <p>
          This profile editor is separate from the homepage and writes directly to the
          backend record attached to the active OAuth account.
        </p>
      </div>

      <div className="profile-workspace__grid">
        <div className="profile-panel surface">
          <div className="profile-panel__header">
            <div>
              <p className="eyebrow">Backend profile</p>
              <h3>
                {isAuthenticated
                  ? 'Edit the backend profile tied to this browser session.'
                  : 'Sign in to unlock the profile page.'}
              </h3>
            </div>
            <span className={statusClass}>{statusLabel}</span>
          </div>

          {notice ? (
            <div className={`workspace-notice workspace-notice--${notice.tone}`} role="status">
              <strong>{notice.title}</strong>
              <span>{notice.body}</span>
            </div>
          ) : null}

          {error ? (
            <div className="workspace-notice workspace-notice--error" role="alert">
              <strong>Profile request failed</strong>
              <span>{error}</span>
            </div>
          ) : null}

          {!isAuthenticated ? (
            <SignInRequired
              copy="The backend scopes each profile to the active OAuth session, so sign-in is required before a record can be created or edited."
              onOpenLogin={onOpenLogin}
            />
          ) : loading ? (
            <div className="profile-skeleton" aria-hidden="true">
              <SkeletonBlock className="profile-skeleton__line profile-skeleton__line--title" />
              <SkeletonBlock className="profile-skeleton__line" />
              <SkeletonBlock className="profile-skeleton__line" />
              <SkeletonBlock className="profile-skeleton__line profile-skeleton__line--wide" />
            </div>
          ) : (
            <form className="profile-form" onSubmit={handleSubmit}>
              <div className="profile-form__grid">
                <label className="profile-field">
                  <span>Display name</span>
                  <input
                    className={`profile-field__control${
                      fieldErrors.displayName ? ' profile-field__control--error' : ''
                    }`}
                    name="displayName"
                    type="text"
                    value={form.displayName}
                    onChange={handleFieldChange}
                    placeholder="Operator display name"
                    autoComplete="name"
                  />
                  {fieldErrors.displayName ? <small>{fieldErrors.displayName[0]}</small> : null}
                </label>

                <label className="profile-field">
                  <span>Headline</span>
                  <input
                    className={`profile-field__control${
                      fieldErrors.headline ? ' profile-field__control--error' : ''
                    }`}
                    name="headline"
                    type="text"
                    value={form.headline}
                    onChange={handleFieldChange}
                    placeholder="What this operator profile should communicate"
                  />
                  {fieldErrors.headline ? <small>{fieldErrors.headline[0]}</small> : null}
                </label>

                <label className="profile-field">
                  <span>Company</span>
                  <input
                    className={`profile-field__control${
                      fieldErrors.company ? ' profile-field__control--error' : ''
                    }`}
                    name="company"
                    type="text"
                    value={form.company}
                    onChange={handleFieldChange}
                    placeholder="XMAXX"
                    autoComplete="organization"
                  />
                  {fieldErrors.company ? <small>{fieldErrors.company[0]}</small> : null}
                </label>

                <label className="profile-field">
                  <span>Location</span>
                  <input
                    className={`profile-field__control${
                      fieldErrors.location ? ' profile-field__control--error' : ''
                    }`}
                    name="location"
                    type="text"
                    value={form.location}
                    onChange={handleFieldChange}
                    placeholder="City, State"
                    autoComplete="address-level2"
                  />
                  {fieldErrors.location ? <small>{fieldErrors.location[0]}</small> : null}
                </label>

                <label className="profile-field profile-field--full">
                  <span>Website</span>
                  <input
                    className={`profile-field__control${
                      fieldErrors.websiteUrl ? ' profile-field__control--error' : ''
                    }`}
                    name="websiteUrl"
                    type="url"
                    value={form.websiteUrl}
                    onChange={handleFieldChange}
                    placeholder="https://xmaxx.ai"
                    autoComplete="url"
                  />
                  {fieldErrors.websiteUrl ? <small>{fieldErrors.websiteUrl[0]}</small> : null}
                </label>

                <label className="profile-field profile-field--full">
                  <span>Bio</span>
                  <textarea
                    className={`profile-field__control profile-field__control--textarea${
                      fieldErrors.bio ? ' profile-field__control--error' : ''
                    }`}
                    name="bio"
                    value={form.bio}
                    onChange={handleFieldChange}
                    placeholder="Describe the operator, project, or surface this profile represents."
                    rows={6}
                  />
                  {fieldErrors.bio ? <small>{fieldErrors.bio[0]}</small> : null}
                </label>
              </div>

              <div className="profile-form__actions">
                <motion.button
                  type="submit"
                  className="button button--solid"
                  disabled={submitting || deleting}
                  whileTap={{ scale: submitting || deleting ? 1 : 0.985 }}
                >
                  {submitLabel}
                </motion.button>

                <motion.button
                  type="button"
                  className="button button--ghost"
                  onClick={handleReset}
                  disabled={submitting || deleting}
                  whileTap={{ scale: submitting || deleting ? 1 : 0.985 }}
                >
                  Reset form
                </motion.button>

                {exists ? (
                  <motion.button
                    type="button"
                    className="button button--ghost profile-delete-button"
                    onClick={handleDelete}
                    disabled={submitting || deleting}
                    whileTap={{ scale: submitting || deleting ? 1 : 0.985 }}
                  >
                    {deleting ? 'Deleting...' : 'Delete profile'}
                  </motion.button>
                ) : null}
              </div>
            </form>
          )}
        </div>

        <ProfileIdentityCard
          authState={authState}
          form={form}
          profile={profile}
          isAuthenticated={isAuthenticated}
        />
      </div>
    </Reveal>
  )
}

export function ApiTokensPage({ authState, onOpenLogin }) {
  const isAuthenticated = authState.authenticated && authState.user
  const [tokenLoading, setTokenLoading] = useState(false)
  const [tokenCreating, setTokenCreating] = useState(false)
  const [tokenRevokingKey, setTokenRevokingKey] = useState('')
  const [tokens, setTokens] = useState([])
  const [tokenName, setTokenName] = useState('')
  const [tokenError, setTokenError] = useState('')
  const [tokenFieldErrors, setTokenFieldErrors] = useState(emptyFieldErrors)
  const [tokenNotice, setTokenNotice] = useState(null)
  const [revealedToken, setRevealedToken] = useState(null)

  useEffect(() => {
    if (!isAuthenticated) {
      setTokenLoading(false)
      setTokenCreating(false)
      setTokenRevokingKey('')
      setTokens([])
      setTokenName('')
      setTokenError('')
      setTokenFieldErrors(emptyFieldErrors)
      setTokenNotice(null)
      setRevealedToken(null)
      return undefined
    }

    const controller = new AbortController()

    setTokenLoading(true)
    setTokenError('')
    setTokenFieldErrors(emptyFieldErrors)

    void requestAccessTokens(controller.signal)
      .then((payload) => {
        if (controller.signal.aborted) {
          return
        }

        setTokens(payload.tokens ?? [])
      })
      .catch((requestError) => {
        if (controller.signal.aborted) {
          return
        }

        setTokens([])
        setTokenError(
          requestError instanceof Error
            ? requestError.message
            : 'Unable to load API tokens for this account.',
        )
      })
      .finally(() => {
        if (!controller.signal.aborted) {
          setTokenLoading(false)
        }
      })

    return () => controller.abort()
  }, [authState, isAuthenticated])

  const handleTokenNameChange = (event) => {
    setTokenName(event.target.value)
    setTokenError('')

    setTokenFieldErrors((current) => {
      if (!current.name) {
        return current
      }

      const next = { ...current }
      delete next.name
      return next
    })
  }

  const handleTokenCreate = async (event) => {
    event.preventDefault()

    setTokenCreating(true)
    setTokenError('')
    setTokenFieldErrors(emptyFieldErrors)
    setTokenNotice(null)
    setRevealedToken(null)

    try {
      const payload = await createAccessToken(tokenName)

      setTokens((current) => [payload.token, ...current])
      setTokenName('')
      setRevealedToken({
        plainTextToken: payload.plainTextToken,
        authorizationHeader: payload.authorizationHeader,
      })
      setTokenNotice({
        tone: 'success',
        title: 'Token created',
        body: 'Copy the bearer token now. The full value is only shown once.',
      })
    } catch (requestError) {
      const payload =
        requestError instanceof Error && 'payload' in requestError
          ? requestError.payload
          : {}

      setTokenError(
        requestError instanceof Error
          ? requestError.message
          : 'Unable to create the API token.',
      )
      setTokenFieldErrors(payload?.fields ?? emptyFieldErrors)
    } finally {
      setTokenCreating(false)
    }
  }

  const handleTokenRevoke = async (tokenKey) => {
    if (!tokenKey || tokenRevokingKey) {
      return
    }

    if (!window.confirm('Revoke this API token? Existing clients will stop working.')) {
      return
    }

    setTokenRevokingKey(tokenKey)
    setTokenError('')
    setTokenNotice(null)

    try {
      const payload = await revokeAccessToken(tokenKey)

      setTokens((current) =>
        current.map((token) => (token.tokenKey === tokenKey ? payload.token : token)),
      )
      setTokenNotice({
        tone: 'info',
        title: 'Token revoked',
        body: 'The token remains listed for audit context, but it can no longer be used.',
      })
    } catch (requestError) {
      setTokenError(
        requestError instanceof Error
          ? requestError.message
          : 'Unable to revoke the API token.',
      )
    } finally {
      setTokenRevokingKey('')
    }
  }

  const activeTokenCount = tokens.filter((token) => token.status === 'active').length
  const tokenStatusClass = tokenLoading
    ? 'profile-badge profile-badge--muted'
    : activeTokenCount
      ? 'profile-badge profile-badge--live'
      : isAuthenticated
        ? 'profile-badge profile-badge--warm'
        : 'profile-badge profile-badge--muted'
  const tokenStatusLabel = tokenLoading
    ? 'Loading'
    : !isAuthenticated
      ? 'Locked'
      : activeTokenCount
        ? `${activeTokenCount} active`
        : 'No tokens'

  return (
    <Reveal as={motion.section} className="profile-workspace section-block">
      <div className="section-heading">
        <p className="eyebrow">API Access</p>
        <h2>Generate and manage bearer tokens on a separate API page.</h2>
        <p>
          Token creation now lives away from the landing page, with a dedicated account
          surface for future client authentication and token inventory management.
        </p>
      </div>

      <div className="profile-workspace__grid">
        <div className="profile-panel surface api-access-panel">
          <div className="profile-panel__header">
            <div>
              <p className="eyebrow">Bearer tokens</p>
              <h3>
                {isAuthenticated
                  ? 'Create and revoke bearer tokens for future API clients.'
                  : 'Sign in to generate and manage API access tokens.'}
              </h3>
            </div>
            <span className={tokenStatusClass}>{tokenStatusLabel}</span>
          </div>

          {tokenNotice ? (
            <div className={`workspace-notice workspace-notice--${tokenNotice.tone}`} role="status">
              <strong>{tokenNotice.title}</strong>
              <span>{tokenNotice.body}</span>
            </div>
          ) : null}

          {tokenError ? (
            <div className="workspace-notice workspace-notice--error" role="alert">
              <strong>Token request failed</strong>
              <span>{tokenError}</span>
            </div>
          ) : null}

          {!isAuthenticated ? (
            <SignInRequired
              copy="API tokens are scoped to the signed-in account, so sign-in is required before a token can be created or managed."
              onOpenLogin={onOpenLogin}
            />
          ) : (
            <div className="api-access-panel__body">
              <p className="api-access-panel__copy">
                Tokens are listed per account and the full bearer token is shown only once at
                creation time. Current session: {getIdentityLabel(authState)}.
              </p>

              <form className="token-form" onSubmit={handleTokenCreate}>
                <label className="profile-field profile-field--full">
                  <span>Token name</span>
                  <input
                    className={`profile-field__control${
                      tokenFieldErrors.name ? ' profile-field__control--error' : ''
                    }`}
                    name="tokenName"
                    type="text"
                    value={tokenName}
                    onChange={handleTokenNameChange}
                    placeholder="CLI integration, internal tooling, staging client"
                  />
                  {tokenFieldErrors.name ? <small>{tokenFieldErrors.name[0]}</small> : null}
                </label>

                <motion.button
                  type="submit"
                  className="button button--solid"
                  disabled={tokenCreating || tokenLoading}
                  whileTap={{ scale: tokenCreating || tokenLoading ? 1 : 0.985 }}
                >
                  {tokenCreating ? 'Generating token...' : 'Generate token'}
                </motion.button>
              </form>

              {revealedToken ? (
                <div className="token-reveal surface surface--dark">
                  <p className="eyebrow">Copy now</p>
                  <h4>This bearer token will not be shown again.</h4>

                  <div className="token-reveal__block">
                    <span>Access token</span>
                    <code>{revealedToken.plainTextToken}</code>
                  </div>

                  <div className="token-reveal__block">
                    <span>Authorization header</span>
                    <code>{revealedToken.authorizationHeader}</code>
                  </div>
                </div>
              ) : null}

              {tokenLoading ? (
                <div className="profile-skeleton" aria-hidden="true">
                  <SkeletonBlock className="profile-skeleton__line profile-skeleton__line--title" />
                  <SkeletonBlock className="profile-skeleton__line" />
                  <SkeletonBlock className="profile-skeleton__line profile-skeleton__line--wide" />
                </div>
              ) : tokens.length ? (
                <div className="token-list">
                  {tokens.map((token) => (
                    <article className="token-card" key={token.tokenKey}>
                      <div className="token-card__header">
                        <div>
                          <h4>{token.name}</h4>
                          <p>
                            {token.tokenKey} ••••{token.tokenSuffix}
                          </p>
                        </div>
                        <span
                          className={
                            token.status === 'active'
                              ? 'profile-badge profile-badge--live'
                              : 'profile-badge profile-badge--muted'
                          }
                        >
                          {token.status === 'active' ? 'Active' : 'Revoked'}
                        </span>
                      </div>

                      <dl className="token-card__meta">
                        <div>
                          <dt>Created</dt>
                          <dd>{formatTimestamp(token.createdAt)}</dd>
                        </div>
                        <div>
                          <dt>Last used</dt>
                          <dd>{formatLastUsed(token.lastUsedAt)}</dd>
                        </div>
                      </dl>

                      <div className="token-card__actions">
                        <motion.button
                          type="button"
                          className="button button--ghost"
                          onClick={() => handleTokenRevoke(token.tokenKey)}
                          disabled={token.status !== 'active' || tokenRevokingKey === token.tokenKey}
                          whileTap={{
                            scale:
                              token.status !== 'active' || tokenRevokingKey === token.tokenKey
                                ? 1
                                : 0.985,
                          }}
                        >
                          {tokenRevokingKey === token.tokenKey ? 'Revoking...' : 'Revoke token'}
                        </motion.button>
                      </div>
                    </article>
                  ))}
                </div>
              ) : (
                <div className="profile-empty profile-empty--compact">
                  <p>
                    No bearer tokens exist for this account yet. Generate one when you need a
                    future API client to authenticate outside the browser session.
                  </p>
                </div>
              )}
            </div>
          )}
        </div>

        <TokenIdentityCard
          authState={authState}
          tokens={tokens}
          revealedToken={revealedToken}
          isAuthenticated={isAuthenticated}
        />
      </div>
    </Reveal>
  )
}

/**
 * Lab 8 bonus — Checkly API check (2 regions, 1 min)
 * Deploy: set CHECKLY_API_KEY + CHECKLY_ACCOUNT_ID, then `npx checkly deploy`
 */
const { ApiCheck, AssertionBuilder, Frequency } = require('checkly/constructs')

const publicUrl = process.env.QUICKNOTES_PUBLIC_URL
if (!publicUrl) {
  // Placeholder overwritten when tunnel is up; also set via env at deploy time
  console.warn('QUICKNOTES_PUBLIC_URL not set — set it before checkly deploy')
}

new ApiCheck('quicknotes-health-lab8', {
  name: 'QuickNotes /health (Lab 8 bonus)',
  activated: true,
  muted: false,
  shouldFail: false,
  runParallel: true,
  locations: ['eu-central-1', 'ap-southeast-1'], // Frankfurt + Singapore
  frequency: Frequency.EVERY_1M,
  maxResponseTime: 2000,
  degradedResponseTime: 1500,
  request: {
    method: 'GET',
    url: process.env.QUICKNOTES_PUBLIC_URL
      ? `${process.env.QUICKNOTES_PUBLIC_URL.replace(/\/$/, '')}/health`
      : 'https://turtle-associated-roller-suddenly.trycloudflare.com/health',
    assertions: [
      AssertionBuilder.statusCode().equals(200),
      AssertionBuilder.responseTime().lessThan(2000),
    ],
  },
  alertChannels: [],
})

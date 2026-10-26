#!/usr/bin/env ruby
# Check that the written decisions cover the actual scanner reports.
require 'json'
require 'date'

root = File.expand_path('../..', __dir__)
dir = File.join(root, 'submissions', 'lab9')
read = ->(name) { JSON.parse(File.read(File.join(dir, name))) }
triage = read.call('triage.json')
errors = []
before_keys = []
after_count = 0

%w[image fs config].each do |kind|
  %w[before after].each do |phase|
    report = read.call("trivy-#{kind}-#{phase}.json")
    errors << "Wrong Trivy version in #{kind}-#{phase}" unless report.dig('Trivy', 'Version') == '0.76.1'
    (report['Results'] || []).each do |result|
      %w[Vulnerabilities Secrets Misconfigurations].each do |type|
        (result[type] || []).each do |finding|
          next unless %w[HIGH CRITICAL].include?(finding['Severity'])
          id = finding['VulnerabilityID'] || finding['ID'] || finding['RuleID']
          if phase == 'before'
            before_keys << [kind, result['Target'], id, finding['PkgName']]
          else
            after_count += 1
          end
        end
      end
    end
  end
end
decision_keys = triage.fetch('trivy').map { |t| [t['scan'], t['target'], t['id'], t['package']] }
errors << 'Missing or extraneous HIGH/CRITICAL triage' unless before_keys.sort == decision_keys.sort
errors << 'Remaining HIGH/CRITICAL findings' unless after_count.zero?

config_before = read.call('trivy-config-before.json').fetch('Results').flat_map { |r| (r['Misconfigurations'] || []).map { |m| [r['Target'], m['ID']] } }
config_decisions = triage.fetch('config').map { |t| [t['target'], t['id']] }
errors << 'Config triage mismatch' unless config_before.sort == config_decisions.sort
errors << 'Remaining config failures' unless read.call('trivy-config-after.json').fetch('Results').all? { |r| (r['Misconfigurations'] || []).empty? }

alerts = {}
%w[before after].each do |phase|
  report = read.call("zap-#{phase}.json")
  errors << 'Wrong ZAP version' unless report['@version'] == '2.17.0'
  alerts[phase] = report.fetch('site').flat_map { |s| s.fetch('alerts', []) }
end
refs = alerts.values.flatten.map { |a| a.fetch('alertRef') }.uniq.sort
errors << 'ZAP triage mismatch' unless refs == triage.fetch('zap').map { |t| t['id'] }.sort
triage.fetch('zap').each do |decision|
  id = decision.fetch('id')
  urls = alerts.values.flatten.select { |a| a['alertRef'] == id }.flat_map { |a| a.fetch('instances').map { |i| i.fetch('uri') } }.uniq.sort
  errors << "Incomplete URL triage for #{id}" unless urls == decision.fetch('urls').sort
  if decision['disposition'] == 'FIX'
    errors << "Fixed ZAP finding remains: #{id}" if alerts['after'].any? { |a| a['alertRef'] == id }
  end
end
errors << 'Remaining non-informational ZAP finding' if alerts['after'].any? { |a| a.fetch('riskcode').to_i > 0 }

reviewed = Date.iso8601(triage.fetch('reviewed_on'))
(triage.fetch('trivy') + triage.fetch('config') + triage.fetch('zap')).each do |decision|
  errors << 'Empty triage reason' if decision.fetch('reason', '').strip.empty?
  next unless decision['disposition'] == 'ACCEPT'
  deadline = Date.iso8601(decision.fetch('review_by'))
  errors << 'Acceptance review date outside six months' unless deadline > reviewed && deadline <= (reviewed >> 6)
end

%w[before after].each do |phase|
  bom = read.call("quicknotes-#{phase}.sbom.cdx.json")
  image = read.call("trivy-image-#{phase}.json")
  errors << 'Invalid SBOM identity' unless bom['bomFormat'] == 'CycloneDX' && bom['specVersion'] == '1.7'
  props = bom.dig('metadata', 'component', 'properties')
  image_id = props.find { |p| p['name'] == 'aquasecurity:trivy:ImageID' }.fetch('value')
  errors << "SBOM image mismatch: #{phase}" unless image_id == image.dig('Metadata', 'ImageID')
  expected_go = phase == 'before' ? 'v1.24.13' : 'v1.27.3'
  stdlibs = bom.fetch('components').select { |c| c['name'] == 'stdlib' }
  errors << "Unexpected stdlib: #{phase}" unless stdlibs.size == 2 && stdlibs.all? { |c| c['version'] == expected_go }
end

errors << 'Before ZAP exit code' unless File.read(File.join(dir, 'zap-before.exit-code.txt')).strip == '2'
errors << 'After ZAP exit code' unless File.read(File.join(dir, 'zap-after.exit-code.txt')).strip == '0'
mutation = File.read(File.join(dir, 'mutation-test.log'))
errors << 'Mutation did not fail on missing headers' unless mutation.include?('mutation_test_exit=1') && mutation.include?('X-Content-Type-Options: got ""')
tests = File.read(File.join(dir, 'go-test-container.log'))
errors << 'Race tests missing successful run' unless tests.include?('go1.27.3 linux/arm64') && tests.include?('--- PASS: TestSecurityHeaders_AllRoutes') && tests.match?(/^ok\s+quicknotes\s/)

abort errors.join("\n") unless errors.empty?
puts "PASS: #{before_keys.size} HIGH/CRITICAL occurrences have decisions (#{decision_keys.map { |k| k[2] }.uniq.size} unique CVEs)."
puts 'PASS: 0 HIGH/CRITICAL after fixes; Dockerfile configuration finding fixed.'
puts "PASS: #{refs.size} ZAP alert variants triaged; 0 non-informational alerts after fixes."
puts 'PASS: dated acceptance, CycloneDX/image identity, Go versions, scan exits and mutation guard.'

# frozen_string_literal: true

revisions_logfile = Rails.root.join("..", "..", "revisions.log")

GIT_SHA =
  if File.exist?(revisions_logfile)
    `tail -1 #{revisions_logfile}`.chomp.split(" ")[3].gsub(/\)$/, "")
  elsif Rails.env.development? || Rails.env.test?
    `git rev-parse HEAD`.chomp
  else
    "Unknown SHA"
  end

BRANCH =
  if File.exist?(revisions_logfile)
    `tail -1 #{revisions_logfile}`.chomp.split(" ")[1]
  elsif Rails.env.development? || Rails.env.test?
    `git rev-parse --abbrev-ref HEAD`.chomp
  else
    "Unknown branch"
  end

LAST_DEPLOYED =
  if File.exist?(revisions_logfile)
    deployed = `tail -1 #{revisions_logfile}`.chomp.split(" ")[7]
    Date.parse(deployed).strftime("%d %B %Y")
  else
    "Not in deployed environment"
  end

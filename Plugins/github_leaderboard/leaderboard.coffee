#!/usr/bin/env /usr/local/bin/coffee
#
# <bitbar.title>GitHub pull-requests Leaderboard </bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Fabien Lefrancois</bitbar.author>
# <bitbar.author.github>SparSio</bitbar.author.github>
# <bitbar.desc>Plugin shows leaderboard for pull-requests in configured github org. Items shown in the list are clickable (clicking the link opens up GitHub PR page).</bitbar.desc>
# <bitbar.dependencies>node,coffee</bitbar.dependencies>
#

dotenv    = require 'dotenv'
GitHubApi = require 'github'
Q         = require 'q'
moment    = require 'moment'

dotenv.config { path: __dirname + '/.env' }
github_user                = process.env.GITHUB_USER
github_token               = process.env.GITHUB_TOKEN
github_org                 = process.env.GITHUB_ORG

github = new GitHubApi
    version: "3.0.0",
    debug: false,
    protocol: "https",
    host: "api.github.com",
    pathPrefix: "",
    timeout: 5000,
    headers:
        "user-agent": "bitbar-app"

github.authenticate
    type: "oauth",
    token: github_token

request = (github, scope, fct, params) ->
    defer  = Q.defer()
    params = if params then params else {org: github_org}
    github[scope][fct](
        params
        , (noop, result) ->
            result.q = params.q
            defer.resolve result
    )

    return defer.promise

moment.locale 'fr',
    week:
        dow: 1

last_monday = moment().day(-6).format 'YYYY-MM-DD'
last_sunday = moment().day(0).format 'YYYY-MM-DD'
this_monday = moment().startOf('week').format 'YYYY-MM-DD'
this_sunday = moment().endOf('week').format 'YYYY-MM-DD'

Q.all(
    [
        request(github, 'search', 'issues', { q: "is:pr user:#{github_user} merged:#{last_monday}..#{last_sunday}"  , sort: 'created', order: 'asc'})
        request(github, 'search', 'issues', { q: "is:pr user:#{github_user} merged:#{this_monday}..#{this_sunday}"  , sort: 'created', order: 'asc'})
        request(github, 'search', 'issues', { q: "is:pr user:#{github_user} created:#{last_monday}..#{last_sunday}" , sort: 'created', order: 'asc'})
        request(github, 'search', 'issues', { q: "is:pr user:#{github_user} created:#{this_monday}..#{this_sunday}" , sort: 'created', order: 'asc'})
        request(github, 'search', 'issues', { q: "is:pr is:open user:etna-alternance"                               , sort: 'created', order: 'asc'})
    ]
).spread (merged_last_week, merged_this_week, created_last_week, created_this_week, actual) ->
    console.log "PRS :  #{actual.items.length}" + if actual.items.length > 12 then "↑ :cry: " else " :smile:" + " | dropdown=false"
    console.log "---"
    console.log "this week merged  : #{merged_this_week.items.length} (#{merged_last_week.items.length} last week)   | href=https://github.com/issues?q=" + encodeURIComponent(merged_last_week.q)
    console.log "this week created : #{created_this_week.items.length} (#{created_last_week.items.length} last week) | href=https://github.com/issues?q=" + encodeURIComponent(created_last_week.q)
    console.log "---"

    leaders = {}
    for merged in merged_last_week.items
        leaders[merged.user.login] ||= 0
        leaders[merged.user.login] += 1

    ([k, v] for k, v of leaders)
        .sort (a, b) ->
            b[1] - a[1]
        .map (n, index) ->
            emoji = if index is 0 then ' :beer:' else ''
            console.log  "#{n[0]} : #{n[1]}#{emoji}"

    console.log "---"
    for issue in actual.items
        url = issue.url.replace 'https://api.github.com/repos/', 'https://github.com/'
        console.log "#{issue.user.login} : #{issue.comments} comments for " + issue.repository_url.substr(issue.repository_url.lastIndexOf('/') + 1)
        console.log "#{issue.title} | href=#{url}"


#!/usr/bin/env bash
# yt.sh — YouTube harvester via yt-dlp. No API key, no auth, no login.
#   yt.sh search "<query>" [N]   -> "title || duration || channel || url"
#   yt.sh tracks <url>           -> which caption tracks exist
#   yt.sh transcript <url>       -> clean prose, with an honest provenance header
#
# MEASURED CAVEAT (verified on youtube.com/watch?v=gv0WHhKelSE, an Anthropic talk):
# a video listed under "Available subtitles" — YouTube's *manual* section — still
# rendered "Claude Code" as "Cloud Code" throughout. The manual track was itself
# ASR-derived. So caption provenance CANNOT be read off the metadata, and the only
# safe rule is the unconditional one: captions are SUBSTANCE, never QUOTATION.
set -uo pipefail

# Dependency check. Sourced, not duplicated: five scripts need the same answer, and a missing
# tool must become a NAMED failure rather than an empty result that reads like "nothing found".
_pf="$(dirname "${BASH_SOURCE[0]}")/preflight.sh"; [ -r "$_pf" ] && . "$_pf"

YTDLP="${YTDLP:-$HOME/.local/bin/yt-dlp}"
command -v "$YTDLP" >/dev/null 2>&1 || YTDLP=yt-dlp
REG="${COMPOUND_CHANNELS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/references/channels.tsv}"
# Fail loudly. Without this, every subcommand returned empty output and exit 0, which reads as
# "this channel has nothing" rather than "this channel is not installed" — the difference between
# an honest empty and a silent lie.
command -v "$YTDLP" >/dev/null 2>&1 || {
  echo "yt.sh: yt-dlp not found on PATH (set YTDLP=/path/to/yt-dlp, or install it)." >&2
  echo "This is a missing tool, not an empty result — do not record it as 'no sources found'." >&2
  exit 127
}

# YouTube bot-walls the default web client under load: "Sign in to confirm you're not a bot".
# Measured 2026-09-21: every caption call on this machine walled on the default client while the
# same videos listed and transcribed through the ios/mweb player clients. So a walled call is
# retried once through them, and a wall that survives the retry is reported as a WALL. The old
# message called it VIDEO_UNREADABLE ("deleted, private, members-only"), which blames the video
# for the IP and invites recording a live source as gone.
YT_ERR="$(mktemp -t yt_err.XXXXXX)"; trap 'rm -f "$YT_ERR"' EXIT
ytd() {
  "$YTDLP" "$@" 2>"$YT_ERR"; local rc=$?
  if [ "$rc" -ne 0 ] && grep -q "not a bot" "$YT_ERR"; then
    "$YTDLP" --extractor-args "youtube:player_client=ios,mweb" "$@" 2>"$YT_ERR"; rc=$?
  fi
  return "$rc"
}
walled() { grep -q "not a bot" "$YT_ERR" 2>/dev/null; }
bot_wall_msg() {
  echo "BOT_WALLED — YouTube is refusing this IP (\"confirm you're not a bot\"), even through the" >&2
  echo "  ios/mweb fallback clients. A property of the IP, not the video: back off and retry" >&2
  echo "  later, or pass cookies to yt-dlp. Do not record this video as unreadable or caption-free." >&2
}

clean() {
  sed -e 's/<[^>]*>//g' -e 's/&nbsp;/ /g' -e 's/&amp;/\&/g' \
      -e "s/&#39;/'/g" -e 's/&quot;/"/g' \
  | grep -vE '^(WEBVTT|Kind:|Language:|NOTE|[0-9]+$)' \
  | grep -vE '^[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3} -->' \
  | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
  | grep -v '^$' | awk '!seen[$0]++' \
  | tr '\n' ' ' | tr -s ' ' | fold -s -w 100
}

case "${1:-}" in
  search)
    "$YTDLP" "ytsearch${3:-10}:${2}" --skip-download --flat-playlist \
      --print "%(title)s || %(duration_string)s || %(channel)s || %(webpage_url)s" 2>/dev/null ;;
  tracks)
    # A caption-free video must not look like a broken tool. Measured 2026-09-09 on
    # 4i0W9qAf8K8: this command returned exit 0, ZERO stdout lines and ZERO stderr
    # bytes -- indistinguishable from a failure -- while the raw listing printed two
    # explicit positive signals, "has no automatic captions" and "has no subtitles".
    # The old awk only printed inside the manual-section state, and an empty table
    # prints no section header at all, so the absence lines were filtered out. That
    # is the same defect as passing --quiet, which yt-dlp's own source confirms:
    # YoutubeDL.py:667 sends screen output to stderr under quiet and :1007 returns
    # early, deleting the only assertion of absence there is.
    out="$(ytd --list-subs --skip-download "$2")"; rc=$?
    if [ $rc -ne 0 ]; then
      if walled; then bot_wall_msg; exit 3; fi
      echo "BROKEN: the caption LISTING itself failed (exit $rc) — deleted, private," >&2
      echo "  members-only, or age/region-gated. This says NOTHING about captions." >&2
      exit 3
    fi
    if printf '%s' "$out" | grep -q "has no subtitles\|has no automatic captions"; then
      printf '%s\n' "$out" | grep "has no subtitles\|has no automatic captions" \
        | sed 's/^/-- ASSERTED ABSENCE: /'
    fi
    printf '%s' "$out" | awk '/Available subtitles/{s=1;a=0;print "-- listed as MANUAL:";next}
             /Available automatic/{a=1;s=0;next}
             s&&/^[a-z]/{print "   "$1}
             END{if(a)print "-- automatic (ASR) tracks also present"}'
    # Exit 1 only when BOTH sections asserted absence: that is a real EMPTY, stated
    # by the tool rather than inferred from silence.
    if printf '%s' "$out" | grep -q "has no subtitles" \
       && printf '%s' "$out" | grep -q "has no automatic captions"; then
      echo "EMPTY: both sections asserted absence — this video genuinely has no captions." >&2
      exit 1
    fi ;;
  transcript)
    d="$(mktemp -d)"; url="$2"
    ytd --skip-download --write-subs --write-auto-subs --sub-langs 'en.*' \
      --sub-format vtt -o "$d/cc.%(ext)s" "$url" >/dev/null
    f="$(ls "$d"/cc*.vtt 2>/dev/null | head -1)"
    if [ -z "$f" ]; then
      # A failed FETCH and an absent TRACK are different facts and were previously reported
      # identically. Caught by a control test: a video that had already transcribed successfully
      # later returned NO_SUBTITLES_AVAILABLE under parallel load — that is throttling, and reading
      # it as "this talk has no captions" silently drops a readable source. Ask what tracks exist
      # before concluding anything, and retry once with backoff.
      if ytd --list-subs --skip-download "$url" | grep -qE '^[a-z]{2}(-[A-Za-z]+)?[[:space:]]'; then
        sleep 5
        ytd --skip-download --write-subs --write-auto-subs --sub-langs 'en.*' \
          --sub-format vtt -o "$d/cc.%(ext)s" "$url" >/dev/null
        f="$(ls "$d"/cc*.vtt 2>/dev/null | head -1)"
      fi
      if [ -z "$f" ]; then
        # Capture the listing's EXIT STATUS separately from its output. The earlier version tested
        # only "did any track line appear", so a listing that ERRORED — deleted, private,
        # members-only, age- or region-gated — produced no lines and fell through to a confident
        # "verified: genuinely no caption tracks". A listing that never returned cannot verify an
        # absence. Three outcomes, not two.
        subs="$(ytd --list-subs --skip-download "$url")"; list_rc=$?
        if [ "$list_rc" -ne 0 ]; then
          if walled; then bot_wall_msg; rm -rf "$d"; exit 2; fi
          echo "VIDEO_UNREADABLE — the caption LISTING itself failed (deleted, private," >&2
          echo "  members-only, or age/region-gated). This says nothing about captions: it is a" >&2
          echo "  channel failure, not an absence. Do not record this video as caption-free." >&2
          rm -rf "$d"; exit 2
        fi
        if printf '%s' "$subs" | grep -qE '^[a-z]{2}(-[A-Za-z]+)?[[:space:]]'; then
          if printf '%s' "$subs" | grep -qE '^en(-[A-Za-z]+)?[[:space:]]'; then
            echo "FETCH_FAILED_BUT_TRACKS_EXIST — this is a CHANNEL FAILURE (throttling/bot-wall)," >&2
            echo "  not an absence of captions. Retry later with backoff; do not record as unreadable." >&2
          else
            echo "NO_ENGLISH_TRACK — the video has captions, none of them English. Not a failure and" >&2
            echo "  not an absence: re-run with --sub-langs for a language you can read." >&2
          fi
          rm -rf "$d"; exit 2
        fi
        echo "NO_SUBTITLES_AVAILABLE — verified: the listing returned cleanly and named no tracks." >&2
        rm -rf "$d"; exit 1
      fi
    fi
    echo "PROVENANCE: YouTube captions for $url"
    echo "PROVENANCE: Captions are SUBSTANCE, not QUOTATION. Even tracks YouTube lists as"
    echo "PROVENANCE: 'manual' are frequently ASR-derived and mishear proper nouns (a verified"
    echo "PROVENANCE: case renders 'Claude Code' as 'Cloud Code' end to end). Use this to learn"
    echo "PROVENANCE: WHAT was said and to decide if a source matters. To QUOTE a speaker, confirm"
    echo "PROVENANCE: the wording against the audio or an independent text source, and say you did."
    clean < "$f"
    rm -rf "$d" ;;
  channels)
    # The registry itself. Ships as data (references/channels.tsv) so it is editable without
    # touching this script and diffable when a handle rots.
    awk -F'\t' '!/^#/ && NF>=3 {printf "  @%-20s %-22s %-12s %s\n", $1, $2, $3, $4}' "$REG" ;;
  verify)
    # The collision guard. `@Anthropic` is a Super Mario Maker channel; `@anthropic-ai` is the lab.
    # A handle that returns the wrong name silently mines a stranger, so never add a row without this.
    # Take the first of SEVERAL items, not item 1. A channel's newest entry is often an unaired
    # premiere, a scheduled live stream, or a members-only video — all of which error — and reading
    # that as "dead channel" nearly deleted the densest source in this registry, whose top item was
    # "Premieres in 23 minutes". One unplayable item is not a dead channel.
    got="$("$YTDLP" --skip-download --playlist-items 1:6 --print "%(channel)s" \
           "https://www.youtube.com/@$2/videos" 2>/dev/null | grep -m1 .)"
    if [ -n "$got" ]; then echo "@$2 -> $got"; else echo "@$2 -> UNRESOLVED (dead handle, or region/age-gated)" >&2; exit 1; fi ;;
  csearch)
    # Search WITHIN one channel. This is the capability the whole registry rests on: without it,
    # "mine a channel" means listing everything it ever published.
    "$YTDLP" --flat-playlist --skip-download -I "1:${4:-8}" \
      --print "%(title)s || %(duration_string)s || %(webpage_url)s" \
      "https://www.youtube.com/@$2/search?query=$(printf '%s' "$3" | sed 's/ /%20/g')" 2>/dev/null ;;
  mine)
    # One question, every verified channel. The point of the registry: you do not decide in advance
    # which lane holds the answer — you ask all of them and let the titles rank themselves.
    q="$2"; per="${3:-4}"
    [ -n "$q" ] || { echo "usage: yt.sh mine \"<query>\" [per-channel]" >&2; exit 2; }
    nch="$(awk -F'\t' '!/^#/ && NF>=3' "$REG" | wc -l | tr -d ' ')"
    echo "# mining ${q} across $nch verified channels"
    # COUNT THE FAILURES, not just the empties. The (0) marker exists to separate "this channel has
    # nothing on your question" from "this channel vanished" — but the loop discarded yt-dlp's exit
    # status, so a yt-dlp that is installed and BROKEN (an outdated build, a bot-walled IP, no
    # network) printed (0) for all 32 channels at exit 0. Measured: a complete-looking sweep that
    # found nothing, with no hint that the tool never ran. YouTube bot-walls fresh IPs routinely, so
    # this is the common case for a new user, not an exotic one. The pipeline runs the loop in a
    # subshell, so the tally goes through a file rather than a variable.
    errf="$(mktemp)"; trap 'rm -f "$errf" "$YT_ERR"' EXIT
    awk -F'\t' '!/^#/ && NF>=3 {print $1"\t"$2}' "$REG" | while IFS="$(printf '\t')" read -r h name; do
      hits="$("$YTDLP" --flat-playlist --skip-download -I "1:$per" \
        --print "$name || %(title)s || %(duration_string)s || %(webpage_url)s" \
        "https://www.youtube.com/@$h/search?query=$(printf '%s' "$q" | sed 's/ /%20/g')" 2>/dev/null)"
      [ "$?" -ne 0 ] && printf 'x' >> "$errf"
      if [ -n "$hits" ]; then printf '%s\n' "$hits"
      else printf '#   (0) %s\n' "$name"
      fi
    done
    errs="$(wc -c < "$errf" 2>/dev/null | tr -d ' ')"; errs="${errs:-0}"
    if [ "$errs" -gt 0 ] && [ "$errs" -ge "$nch" ]; then
      echo "" >&2
      echo "TOOL FAILURE, NOT AN EMPTY RESULT: yt-dlp failed on ALL $nch channels." >&2
      echo "  Every (0) above is a FAILED CALL, not a channel without matches. Do NOT record this" >&2
      echo "  sweep as 'no talks found' — nothing was actually searched." >&2
      echo "  Likely causes: yt-dlp out of date (run: yt-dlp -U), no network, or YouTube serving a" >&2
      echo "  bot-wall to this IP. Check with: $YTDLP --version && $YTDLP --flat-playlist -I 1:1 \\" >&2
      echo "    --print '%(title)s' https://www.youtube.com/@LennysPodcast/videos" >&2
      exit 3
    elif [ "$errs" -gt 0 ]; then
      echo "# NOTE: $errs of $nch channels FAILED (not empty). Their (0) lines are unmeasured." >&2
    fi
    # A channel that returned nothing prints a (0) line rather than vanishing. Silence and
    # "this lane has nothing on your question" look identical otherwise, and one of them is a
    # broken query while the other is a finding.
    echo "# Titles only. Pick by what the TALK is, never by channel prestige, then:"
    echo "#   bash scripts/yt.sh transcript <url>   — full text, ~5k words for a 25-min talk"
    echo "# Captions are SUBSTANCE, not QUOTATION (references/public-sources.md)." ;;
  titles)
    # RECALL FIRST. Dump the channel's whole title list — ~1,100 titles in ~13s — and filter it
    # locally. YouTube's own in-channel search (csearch/mine) matches titles fuzzily and silently
    # UNDER-collects, which is the wrong error: a talk you never listed cannot be judged, while a
    # talk you listed and skipped costs one line. Newest first, so `limit` is a recency window.
    "$YTDLP" --flat-playlist --skip-download ${3:+-I "1:$3"} \
      --print "%(title)s || %(webpage_url)s" \
      "https://www.youtube.com/@$2/videos" 2>/dev/null ;;
  sweep)
    # The recall-first counterpart to `mine`: dump titles from EVERY registry channel and grep them
    # here, with your own regex, instead of trusting YouTube's matcher. Be generous with the regex —
    # a false positive costs one transcript, a false negative costs a source you never knew existed.
    pat="${2:?usage: yt.sh sweep \"<extended-regex>\" [per-channel-limit] [tier]}"; lim="${3:-400}"
    total=0; errs=0; nch=0
    echo "# sweeping /$pat/i over the newest $lim titles of each ${4:-all}-tier channel"
    while IFS="$(printf '\t')" read -r h name; do
      [ -n "$h" ] || continue
      nch=$((nch + 1))
      # Capture yt-dlp's status BEFORE piping to grep. Written as one pipeline, `$?` was grep's
      # status and yt-dlp's failure was unobservable — so a broken or bot-walled yt-dlp printed
      # (0) for every channel at exit 0. This is the lane alpha.sh actually calls, so that silent
      # lie was the default experience for anyone whose yt-dlp was stale or whose IP was walled.
      raw="$("$YTDLP" --flat-playlist --skip-download -I "1:$lim" \
        --print "$name || %(title)s || %(webpage_url)s" \
        "https://www.youtube.com/@$h/videos" 2>/dev/null)" || errs=$((errs + 1))
      hits="$(printf '%s' "$raw" | grep -iE "$pat")"
      n=$(printf '%s' "$hits" | grep -c . )
      total=$((total + n))
      if [ "$n" -gt 0 ]; then printf '%s\n' "$hits"; else printf '#   (0) %s\n' "$name"; fi
    done < <(awk -F'\t' -v t="${4:-all}" '!/^#/ && NF>=3 && (t=="all" || $3==t) {print $1"\t"$2}' "$REG")
    if [ "$errs" -gt 0 ] && [ "$errs" -ge "$nch" ]; then
      echo "" >&2
      echo "TOOL FAILURE, NOT AN EMPTY RESULT: yt-dlp failed on ALL $nch channels." >&2
      echo "  Every (0) above is a FAILED CALL, not a channel without matches. Nothing was searched," >&2
      echo "  so do NOT record this sweep as 'no talks found'." >&2
      echo "  Likely: yt-dlp out of date (yt-dlp -U), no network, or a YouTube bot-wall on this IP." >&2
      exit 3
    elif [ "$errs" -gt 0 ]; then
      echo "# NOTE: $errs of $nch channels FAILED (not empty). Their (0) lines are unmeasured." >&2
    fi
    echo "# $total titles matched. Widen the regex if that feels thin — under-collecting is the"
    echo "# expensive error here. Then: bash scripts/yt.sh transcript <url>"
    echo "# Captions are SUBSTANCE, not QUOTATION (references/public-sources.md)." ;;
  *) echo "usage: yt.sh {titles|sweep|csearch|mine|channels|verify|tracks|transcript} ..." >&2; exit 2 ;;
esac

# Coding rules for Cursor Cloud Agents (J H)
Scope: code only. You work in this repo on a branch. Report in short Korean.

## Must not
1. Never add trading data, strategy notes, labels, transcripts, chart screenshots, or Falcon private content.
2. Never push to main, merge, delete shared branches, publish, sign up, or add paid services without J H approval — ask via report; keep work on a feature branch.
3. Never fabricate. Every claim needs real command output you ran this turn.
4. Never expand scope past the assigned task.

## Must
5. Prefer reversible changes (branch + small commits). Back up or keep a way to undo before risky edits.
6. Prove it works: run `bash scripts/check.sh` (and project tests) before reporting done. Paste commands + results.
7. Two identical failures → change approach on the third try. Do not loop the same broken method.
8. Subtract before you add. Prefer the smallest diff that solves the problem.
9. Before designing a system or feature, search related open source and references (GitHub, HF, official docs); note stars, last commit, license, and adopt/reference/skip, then design.
10. Keep AGENTS.md ≤ 40 lines. Put longer guidance in skills or docs, not here.

## Unblock order
retry once → diagnose from logs/errors → try an alternative → search docs → small isolated trial → then report blockers to J H (stop).

## Skills
Use `.cursor/skills/` (pstack principles + `correct`). Rules in `.cursor/rules/jh-core.mdc` always apply.

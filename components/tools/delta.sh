#!/usr/bin/env bash
# Bileşen: delta — okunaklı git diff. Git ayarlarının önceki değerleri
# deftere yazılır; kaldırınca git eski haline döner.

component_register delta "delta" tools "Okunaklı git diff" ""

comp_delta_install() {
    act_gh_binary dandavison/delta 'x86_64-unknown-linux-musl\.tar\.gz$' 'aarch64-unknown-linux-gnu\.tar\.gz$' delta || return 1
    act_gitcfg core.pager delta &&
    act_gitcfg interactive.diffFilter "delta --color-only" &&
    act_gitcfg delta.navigate true &&
    act_gitcfg merge.conflictStyle diff3 &&
    act_gitcfg diff.colorMoved default
}

comp_delta_verify() { has_cmd delta; }

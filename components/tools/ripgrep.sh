#!/usr/bin/env bash
# Bileşen: ripgrep — çok hızlı grep (rg)

component_register ripgrep "ripgrep" tools "Çok hızlı içerik arama (rg)" ""

component_tip ripgrep "rg kelime" "Dizinde çok hızlı içerik ara"

comp_ripgrep_install() {
    act_pkg ripgrep || return 1
    act_write_file "$TS_CONFIG_DIR/ripgreprc" "--max-columns=150
--max-columns-preview
--smart-case" || return 1
    act_zsh_snippet 60 ripgrep "export RIPGREP_CONFIG_PATH=\"$TS_CONFIG_DIR/ripgreprc\""
}

comp_ripgrep_verify() { has_cmd rg; }

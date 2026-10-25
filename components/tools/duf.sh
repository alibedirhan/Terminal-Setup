#!/usr/bin/env bash
# Bileşen: duf — okunaklı df

component_register duf "duf" tools "Disk bölümleri (df)" ""

component_tip duf "duf" "Disk bölümlerinin doluluğu"

comp_duf_install() { act_pkg duf; }

comp_duf_verify() { has_cmd duf; }

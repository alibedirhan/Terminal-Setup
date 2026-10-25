#!/usr/bin/env bash
# Bileşen: duf — okunaklı df

component_register duf "duf" tools "Disk bölümleri (df)" ""

comp_duf_install() { act_pkg duf; }

comp_duf_verify() { has_cmd duf; }
